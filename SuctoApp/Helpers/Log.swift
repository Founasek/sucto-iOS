//
//  Log.swift
//  SuctoApp
//

import Foundation

enum Log {
    /// Loguje pouze v Debug buildu. Nikdy neloguj tokeny, hesla ani těla požadavků.
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
            print(message())
        #endif
    }
}
