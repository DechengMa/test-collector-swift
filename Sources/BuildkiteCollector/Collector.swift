import Core

public enum Collector {
  /// Annotates the current test.
  ///
  /// The provided content is added to the collected span data and will appear in the span timeline.
  ///
  /// - Parameter content: The content of this annotation
  public static func annotate(_ content: @autoclosure () -> String) {
    Core.Collector.shared?.annotate(content())
  }
}
