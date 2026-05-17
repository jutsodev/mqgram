load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MQDeletedMessagesUI",
    module_name = "MQDeletedMessagesUI",
    srcs = glob(["Sources/**/*.swift"]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/ItemListUI:ItemListUI",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/AccountContext:AccountContext",
        "//MQGram/MQDeletedMessages:MQDeletedMessages",
    ],
    visibility = ["//visibility:public"],
)
