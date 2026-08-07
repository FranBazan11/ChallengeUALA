//
//  URLSessionHTTPClientTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import XCTest
import Cities

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        super.tearDown()
    }

    func test_getFromURL_performsGETRequestWithURL() async {
        let url = anyURL()
        let requestExpectation = expectation(description: "Wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            requestExpectation.fulfill()
        }

        _ = try? await makeSUT().get(from: url)

        await fulfillment(of: [requestExpectation], timeout: 1.0)
    }

    func test_getFromURL_failsOnRequestError() async {
        let requestError = anyNSError()

        let receivedError = await resultErrorFor(data: nil, response: nil, error: requestError)

        let receivedNSError = receivedError as? NSError
        XCTAssertEqual(receivedNSError?.domain, requestError.domain)
        XCTAssertEqual(receivedNSError?.code, requestError.code)
    }

    func test_getFromURL_failsOnNonHTTPURLResponse() async {
        let receivedError = await resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil)

        XCTAssertNotNil(receivedError)
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async {
        let data = anyData()
        let response = anyHTTPURLResponse()

        let receivedValues = await resultValuesFor(data: data, response: response, error: nil)

        expect(receivedValues, toDeliver: data, response: response)
    }

    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() async {
        let response = anyHTTPURLResponse()

        let receivedValues = await resultValuesFor(data: nil, response: response, error: nil)

        expect(receivedValues, toDeliver: Data(), response: response)
    }

    // MARK: - Helpers

    private func makeSUT() -> URLSessionHTTPClient {
        URLSessionHTTPClient()
    }

    private func expect(
        _ receivedValues: (data: Data, response: HTTPURLResponse)?,
        toDeliver expectedData: Data,
        response expectedResponse: HTTPURLResponse,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(receivedValues?.data, expectedData, file: file, line: line)
        XCTAssertEqual(receivedValues?.response.url, expectedResponse.url, file: file, line: line)
        XCTAssertEqual(receivedValues?.response.statusCode, expectedResponse.statusCode, file: file, line: line)
    }

    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Error? {
        let result = await resultFor(data: data, response: response, error: error)

        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultValuesFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> (data: Data, response: HTTPURLResponse)? {
        let result = await resultFor(data: data, response: response, error: error)

        switch result {
        case let .success(values):
            return values
        default:
            XCTFail("Expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) async -> Result<(data: Data, response: HTTPURLResponse), Error> {
        URLProtocolStub.stub(data: data, response: response, error: error)

        do {
            let (data, response) = try await makeSUT().get(from: anyURL())
            return .success((data, response))
        } catch {
            return .failure(error)
        }
    }

    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private final class URLProtocolStub: URLProtocol {
        private static let stateLock = NSLock()
        private nonisolated(unsafe) static var stubStorage: Stub?
        private nonisolated(unsafe) static var requestObserverStorage: ((URLRequest) -> Void)?

        private static var stub: Stub? {
            get { stateLock.withLock { stubStorage } }
            set { stateLock.withLock { stubStorage = newValue } }
        }

        private static var requestObserver: ((URLRequest) -> Void)? {
            get { stateLock.withLock { requestObserverStorage } }
            set { stateLock.withLock { requestObserverStorage = newValue } }
        }

        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }

        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }

            let currentStub = URLProtocolStub.stub

            if let data = currentStub?.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let response = currentStub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error = currentStub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
