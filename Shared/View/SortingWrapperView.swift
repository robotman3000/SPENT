//
//  SortingWrapperView.swift
//  SPENT
//
//  Created by Eric Nims on 9/5/21.
//

import SwiftUI


struct SortingWrapperView<Agent: SortingAgent, Content: View>: View { //<, Content: View>: View {
//    @Binding var data: [Agent.Value]
//    @State var sortedData: [Agent.Value]
//    var content: ([Agent.Value]) -> Content
//
//    init(data: Binding<Agent.Value>, @ViewBuilder content: @escaping ([Agent.Value]) -> Content) {
//        self.data = data
//        self.content = content
//    }
//
//    var body: some View {
//        content(query)
//    }
    
    var agent: Agent
    var input: [Agent.Value]
    var content: ([Agent.Value]) -> Content
    
    init(agent: Agent, input: [Agent.Value], @ViewBuilder content: @escaping ([Agent.Value]) -> Content) {
        self.agent = agent
        self.input = input
        self.content = content
    }
        
    var body: some View {
        let output = agent.sort(input)
        content(output)
    }
}

