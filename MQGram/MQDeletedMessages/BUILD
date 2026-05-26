load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MQDeletedMessages",
    module_name = "MQDeletedMessages",
    srcs = glob(["Sources/**/*.swift"]),
    copts = [
    ],
    deps = [
        "//submodules/Postbox:Postbox",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/TelegramCore:TelegramCore",
        "//MQGram/MQGramDatabase:MQGramDatabase",
    ],
    visibility = ["//visibility:public"],
)
