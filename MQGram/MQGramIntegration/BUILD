load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MQGramIntegration",
    module_name = "MQGramIntegration",
    srcs = glob([
        "*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display:Display",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/TelegramCore:TelegramCore",
        "//MQGram/MQGramSettingsUI:MQGramSettingsUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
