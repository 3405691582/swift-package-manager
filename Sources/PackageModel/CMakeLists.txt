# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for Swift project authors

add_library(PackageModel
  BuildConfiguration.swift
  BuildEnvironment.swift
  BuildSettings.swift
  ContextModel.swift
  Diagnostics.swift
  Manifest.swift
  Manifest/PackageConditionDescription.swift
  Manifest/PackageDependencyDescription.swift
  Manifest/PlatformDescription.swift
  Manifest/ProductDescription.swift
  Manifest/SystemPackageProviderDescription.swift
  Manifest/TargetBuildSettingDescription.swift
  Manifest/TargetDescription.swift
  ManifestSourceGeneration.swift
  ModuleMapType.swift
  Package.swift
  PackageIdentity.swift
  PackageReference.swift
  Platform.swift
  Product.swift
  Resource.swift
  Snippets/Model/Snippet.swift
  Snippets/Model/SnippetGroup.swift
  Snippets/Parsing/PlainTextSnippetExtractor.swift
  Sources.swift
  SupportedLanguageExtension.swift
  SwiftLanguageVersion.swift
  Target.swift
  ToolchainConfiguration.swift
  ToolsVersion.swift
  ToolsVersionSpecificationGeneration.swift)
target_link_libraries(PackageModel PUBLIC
  TSCBasic
  TSCUtility
  Basics)
# NOTE(compnerd) workaround for CMake not setting up include flags yet
set_target_properties(PackageModel PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

if(USE_CMAKE_INSTALL)
install(TARGETS PackageModel
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin)
endif()
set_property(GLOBAL APPEND PROPERTY SwiftPM_EXPORTS PackageModel)
