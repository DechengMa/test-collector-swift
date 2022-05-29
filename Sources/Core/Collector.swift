import Dispatch
import XCTest

public struct Collector {
  let observer: TestObserver?

  /// Constructs a collected using the provided environment values
  ///
  /// - Parameter environment: The environment values.
  init(
    environment: EnvironmentValues = EnvironmentValues(),
    logger: Logger? = nil
  ) {
    guard environment.isAnalyticsEnabled else {
      // To prevent error when loading collector during `--list-tests`
      DispatchQueue.main.async {
        logger?.info("Collector disabled. Test results will not be collected.")
      }
      self.observer = nil
      return
    }

    let tracer = Tracer.live()

    let uploader: UploadClient?
    if let apiToken = environment.analyticsToken {
      let api = ApiClient.live(apiToken: apiToken)
      let runEnvironment = environment.runEnvironment()
      uploader = .live(api: api, logger: logger, runEnvironment: runEnvironment)
    } else {
      // To prevent error when loading collector during `--list-tests`
      DispatchQueue.main.async {
        logger?.info("Collector unable to locate API key. Test results will not be uploaded.")
      }
      uploader = nil
    }

    self.observer = TestObserver(logger: logger, tracer: tracer, uploader: uploader)
  }

  /// Annotates the current test.
  ///
  /// The provided content is added to the collected span data and will appear in the span timeline.
  ///
  /// - Parameter content: The content of this annotation
  public func annotate(_ content: @autoclosure () -> String) {
    self.observer?.tracer.annotate(content()) // TODO: Should this be thread safe?
  }

  /// Configures the shared collector.
  ///
  /// Used by the root target to create a collector and add it to the test observation center.
  ///
  /// - Note: It is important that this method does not print synchronously eg. inside the Collector.init. Printing to the console here
  /// causes an error  when using `swift test --list-tests` and `--parallel` on Linux.
  public static func load() {
    // TODO: Find out exactly why printing causes problems
    guard self.shared == nil else { return }
    let environment = EnvironmentValues()
    let logger = Logger(logLevel: environment.isAnalyticsDebugEnabled ? .debug : .info)
    self.shared = Collector(environment: environment, logger: logger)
    self.shared?.observer.map(XCTestObservationCenter.shared.addTestObserver)
  }

  public private(set) static var shared: Collector?
}
