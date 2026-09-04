#!/bin/sh

# Disable Swift Macro fingerprint validation in Xcode Cloud
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# Disable Swift Package Plugin fingerprint validation in Xcode Cloud
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
