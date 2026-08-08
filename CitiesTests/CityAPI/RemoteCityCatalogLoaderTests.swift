//
//  RemoteCityCatalogLoaderTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import XCTest
import Cities

final class RemoteCityCatalogLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() async {
        let (_, client) = makeSUT()

        let requestedURLs = await client.requestedURLs

        XCTAssertTrue(requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() async {
        let url = anyURL()
        let (sut, client) = makeSUT(url: url)

        let task = load(sut)
        await client.awaitRequests(count: 1)

        let requestedURLs = await client.requestedURLs
        XCTAssertEqual(requestedURLs, [url])

        await client.complete(withStatusCode: 200, data: makeCatalogJSON([]))
        _ = await task.value
    }

    func test_loadTwice_requestsDataFromURLTwice() async {
        let url = anyURL()
        let (sut, client) = makeSUT(url: url)

        let firstTask = load(sut)
        await client.awaitRequests(count: 1)
        let secondTask = load(sut)
        await client.awaitRequests(count: 2)

        let requestedURLs = await client.requestedURLs
        XCTAssertEqual(requestedURLs, [url, url])

        await client.complete(withStatusCode: 200, data: makeCatalogJSON([]), at: 0)
        await client.complete(withStatusCode: 200, data: makeCatalogJSON([]), at: 1)
        _ = await firstTask.value
        _ = await secondTask.value
    }

    func test_load_onClientError_deliversConnectivityError() async {
        let (sut, client) = makeSUT()

        await expect(sut, client: client, toCompleteWith: .failure(.connectivity)) {
            await client.complete(with: anyNSError())
        }
    }

    func test_load_onNon200HTTPResponse_deliversInvalidDataError() async {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]

        for (index, statusCode) in samples.enumerated() {
            await expect(sut, client: client, toCompleteWith: .failure(.invalidData)) {
                await client.complete(withStatusCode: statusCode, data: makeCatalogJSON([]), at: index)
            }
        }
    }

    func test_load_on200ResponseWithInvalidJSON_deliversInvalidDataError() async {
        let (sut, client) = makeSUT()

        await expect(sut, client: client, toCompleteWith: .failure(.invalidData)) {
            await client.complete(withStatusCode: 200, data: Data("no soy json".utf8))
        }
    }

    func test_load_on200ResponseWithEmptyJSONList_deliversEmptyCatalog() async {
        let (sut, client) = makeSUT()

        await expect(sut, client: client, toCompleteWith: .success(CityCatalog(cities: []))) {
            await client.complete(withStatusCode: 200, data: makeCatalogJSON([]))
        }
    }

    func test_load_on200ResponseWithJSONCities_deliversCatalog() async {
        let (sut, client) = makeSUT()
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let denver = makeCity(id: 5419384, name: "Denver", countryCode: "US", latitude: 39.739151, longitude: -104.984703)

        await expect(sut, client: client, toCompleteWith: .success(CityCatalog(cities: [hurzuf.model, denver.model]))) {
            await client.complete(withStatusCode: 200, data: makeCatalogJSON([hurzuf.json, denver.json]))
        }
    }

    func test_load_onTaskCancelledBeforeTheResponseArrives_deliversCancelledError() async {
        let (sut, client) = makeSUT()

        let task = load(sut)
        await client.awaitRequests(count: 1)
        task.cancel()

        await client.complete(withStatusCode: 200, data: makeCatalogJSON([]))
        let result = await task.value

        switch result {
        case .failure(.cancelled):
            break
        default:
            XCTFail("Expected .cancelled, got \(result) instead")
        }
    }

    func test_load_onClientErrorAfterTaskWasCancelled_deliversCancelledError() async {
        let (sut, client) = makeSUT()

        let task = load(sut)
        await client.awaitRequests(count: 1)
        task.cancel()

        await client.complete(with: anyNSError())
        let result = await task.value

        switch result {
        case .failure(.cancelled):
            break
        default:
            XCTFail("Expected .cancelled, got \(result) instead")
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        url: URL = anyURL(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteCityCatalogLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteCityCatalogLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }

    private func load(_ sut: RemoteCityCatalogLoader) -> Task<Result<CityCatalog, CityCatalogLoadError>, Never> {
        Task { await RemoteCityCatalogLoaderTests.resultOf(sut) }
    }

    private static func resultOf(_ sut: RemoteCityCatalogLoader) async -> Result<CityCatalog, CityCatalogLoadError> {
        do {
            return .success(try await sut.load())
        } catch {
            return .failure(error)
        }
    }

    private func expect(
        _ sut: RemoteCityCatalogLoader,
        client: HTTPClientSpy,
        toCompleteWith expectedResult: Result<CityCatalog, CityCatalogLoadError>,
        when action: @escaping () async -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let requestsBefore = await client.requestedURLs.count
        async let receivedResult = Self.resultOf(sut)
        await client.awaitRequests(count: requestsBefore + 1)
        await action()

        let result = await receivedResult
        switch (result, expectedResult) {
        case let (.success(receivedCatalog), .success(expectedCatalog)):
            XCTAssertEqual(receivedCatalog.cities, expectedCatalog.cities, file: file, line: line)
        case let (.failure(receivedError), .failure(expectedError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        default:
            XCTFail("Expected \(expectedResult), got \(result) instead", file: file, line: line)
        }
    }

    private actor HTTPClientSpy: HTTPClient {
        private(set) var requestedURLs = [URL]()
        private var pendingCompletions = [CheckedContinuation<(Data, HTTPURLResponse), Error>]()
        private var requestWaiters = [(count: Int, continuation: CheckedContinuation<Void, Never>)]()

        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            requestedURLs.append(url)
            resumeSatisfiedWaiters()
            return try await withCheckedThrowingContinuation { continuation in
                pendingCompletions.append(continuation)
            }
        }

        func awaitRequests(count: Int) async {
            if requestedURLs.count >= count { return }
            await withCheckedContinuation { continuation in
                requestWaiters.append((count, continuation))
            }
        }

        private func resumeSatisfiedWaiters() {
            let satisfied = requestWaiters.filter { requestedURLs.count >= $0.count }
            requestWaiters.removeAll { requestedURLs.count >= $0.count }
            satisfied.forEach { $0.continuation.resume() }
        }

        func complete(with error: Error, at index: Int = 0) {
            pendingCompletions[index].resume(throwing: error)
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            pendingCompletions[index].resume(returning: (data, response))
        }
    }
}
