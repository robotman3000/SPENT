//
//  QueryWrapperView.swift
//  SPENT
//
//  Created by Eric Nims on 7/3/21.
//

import SwiftUI
import Combine
import GRDB

struct QueryWrapperView<Source: Queryable, Content: View>: View {
    @Query<Source> var query: Source.Value
    var content: (Source.Value) -> Content

    init(source: Source, @ViewBuilder content: @escaping (Source.Value) -> Content) {
        self._query = Query(source)
        self.content = content
    }
    
    var body: some View {
        content(query)
    }
}

struct AsyncContentView<Source: LoadableObject, Content: View>: View {
    @EnvironmentObject var store: DatabaseStore
    @ObservedObject var source: Source
    var content: (Source.Output) -> Content
    var id = UUID()
    var debugInitMessage: String
    
    init(source: Source,  _ debugInitMessage: String = "", @ViewBuilder content: @escaping (Source.Output) -> Content) {
        self.source = source
        self.content = content
        if !debugInitMessage.isEmpty {
            print("[UI Debugging]: Initializing AsyncContentView(\(id)): \(debugInitMessage)")
        }
        self.debugInitMessage = debugInitMessage
        source.load(id: id)
    }
    
    var body: some View {
        //Color.clear.onAppear(perform: {print("Asunc appear \(id)")})
        switch source.state {
        case .idle:
            Text("Idle \(id)")//.onAppear(perform: {source.load(id: id)})
            //
        case .loading:
            ProgressView()
        case .failed(let error):
            Text("Error \(error.localizedDescription)")
            //ErrorView(error: error, retryHandler: source.load)
        case .loaded(let output):
            //Text(id.uuidString)
            content(output)
        }
    }
}

extension AsyncContentView {
    init<P: Publisher>(
        source: P,
        _ debugInitMessage: String = "",
        @ViewBuilder content: @escaping (P.Output) -> Content
    ) where Source == PublishedObject<P> {
        self.init(
            source: PublishedObject(publisher: source),
            debugInitMessage,
            content: content
        )
    }
}

enum LoadingState<Value> {
    case idle
    case loading
    case failed(Error)
    case loaded(Value)
}

protocol LoadableObject: ObservableObject {
    associatedtype Output
    var state: LoadingState<Output> { get }
    func load(id: UUID)
}

class PublishedObject<Wrapped: Publisher>: LoadableObject {
    @Published private(set) var state = LoadingState<Wrapped.Output>.idle

    private let publisher: Wrapped
    private var cancellable: AnyCancellable?

    init(publisher: Wrapped) {
        self.publisher = publisher
    }

    func load(id: UUID) {
        print("[UI Debugging]: PublishedObject[\(id)]: .load()")
        state = .loading

        cancellable = publisher
            .receive(on: DispatchQueue.main)
            .map(LoadingState.loaded)
            .catch { error in
                Just(LoadingState.failed(error))
            }
            .sink { [weak self] state in
                print("[UI Debugging]: PublishedObject[\(id)]: .sink(\(self)")
                self?.state = state
            }
    }
}


//struct QueryWrapperView_Previews: PreviewProvider {
//    static var previews: some View {
//        QueryWrapperView()
//    }
//}
