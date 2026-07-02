protocol IconVisibilityControlling {
    func apply(mode: PlacementMode, to record: MenuBarItemRecord) -> HideSupportStatus
}

final class IconVisibilityController: IconVisibilityControlling {
    func apply(mode: PlacementMode, to record: MenuBarItemRecord) -> HideSupportStatus {
        switch mode {
        case .realMenuBar, .both:
            return record.hideSupportStatus
        case .virtualMenu:
            return .virtualOnlyUnsupported
        }
    }
}
