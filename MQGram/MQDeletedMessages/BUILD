load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MQDeletedMessages",
    module_name = "MQDeletedMessages",
    srcs = glob(["Sources/**/*.swift"]),
    deps = [
        "//submodules/Postbox:Postbox",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//MQGram/MQGramDatabase:MQGramDatabase",
    ],
    visibility = ["//visibility:public"],
)
