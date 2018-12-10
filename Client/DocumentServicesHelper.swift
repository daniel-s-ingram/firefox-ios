/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import JavaScriptCore
import Shared
import Storage
import XCGLogger
import NaturalLanguage

private let log = Logger.browserLogger

class DocumentServicesHelper: TabEventHandler {
    private var tabObservers: TabObservers!

    private lazy var singleThreadedQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Document Services JSContext queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInitiated
        return queue
    }()

    init() {
        self.tabObservers = registerFor(
            .didLoadPageMetadata,
            queue: singleThreadedQueue)
    }

    deinit {
        unregister(tabObservers)
    }

    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        guard let text = metadata.description else { return }
        let language: String?
        if #available(iOS 12.0, *) {
            language = NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
        } else {
            language = NSLinguisticTagger.dominantLanguage(for: text)
        }
        DispatchQueue.global().async {
            TabEvent.post(.didDeriveMetadata(DerivedMetadata(language: language)), for: tab)
        }
    }
}

struct DerivedMetadata {
    let language: String?
}
