//
//  UIForms.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

enum FormKeys: SheetProvider {
    case account(context: SheetContext, account: Bucket?, onSubmit: (_ data: inout Bucket) -> Void)
    case bucket(context: SheetContext, bucket: Bucket?, parent: Bucket?, onSubmit: (_ data: inout Bucket) -> Void)
    case transaction(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, onSubmit: (_ data: inout Transaction) -> Void)
    case transfer(context: SheetContext, transaction: Transaction?, contextBucket: Bucket, onSubmit: (_ data: inout Transaction) -> Void)
    case tag(context: SheetContext, tag: Tag?, onSubmit: (_ data: inout Tag) -> Void)
    case schedule(context: SheetContext, schedule: Schedule?, onSubmit: (_ data: inout Schedule) -> Void)
    case transactionTags(context: SheetContext, transaction: Transaction, onSubmit: (_ tags: [Tag], _ transaction: Transaction) -> Void)
    case splitTransaction(context: SheetContext, splitMembers: [Transaction], contextBucket: Bucket, onSubmit: (_ data: inout [Transaction]) -> Void)
    case transactionTemplate(context: SheetContext, template: DBTransactionTemplate?, onSubmit: (_ data: inout DBTransactionTemplate) -> Void)
    case documentList(context: SheetContext, transaction: Transaction)
    case confirmDelete(context: SheetContext, message: String, onConfirm: () -> Void)
    case confirmAction(context: SheetContext, message: String, onConfirm: () -> Void, onCancel: () -> Void)
    
    var sheet: AnyView {
        switch self {
        case .account(context: let context, account: var account, onSubmit: let handleSubmit):
            if account == nil{
                account = Bucket.newBucket()
            }
            return AccountForm(account: account!, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .bucket(context: let context, bucket: var bucket, parent: let parent, onSubmit: let handleSubmit):
            if bucket == nil{
                bucket = Bucket.newBucket()
            }
            return EmptyView().any()
            //return BucketForm(bucket: bucket!, parent: parent, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transaction(context: let context, transaction: var transaction, contextBucket: let bucket, onSubmit: let handleSubmit):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            return TransactionForm(transaction: transaction!, selectedBucket: bucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transfer(context: let context, transaction: var transaction, contextBucket: let contextBucket, onSubmit: let handleSubmit):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            return TransferForm(transaction: transaction!, selectedSource: contextBucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .tag(context: let context, tag: var tag, onSubmit: let handleSubmit):
            if tag == nil {
                tag = Tag.newTag()
            }
            return TagForm(tag: tag!, onSubmit: handleSubmit, onCancel: { context.dismiss() } ).padding().any()
            
        case .schedule(context: let context, schedule: var schedule, onSubmit: let handleSubmit):
            if schedule == nil {
                schedule = Schedule.newSchedule()
            }
            return EmptyView().any()
            //return ScheduleForm(schedule: schedule!, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transactionTags(context: let context, transaction: let transaction, onSubmit: let handleSubmit):
            return TransactionTagForm(transaction: transaction, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transactionTemplate(context: let context, template: var template, onSubmit: let handleSubmit):
            if template == nil {
                template = DBTransactionTemplate.newTemplate()
            }
            return TemplateForm(dbtemplate: template!, onSubmit: handleSubmit, onCancel:{ context.dismiss() }).padding().any()
            
        case .splitTransaction(context: let context, splitMembers: let members, contextBucket: let contextBucket, onSubmit: let handleSubmit):
            var head: Transaction?
            var newMembers: [Transaction] = []
            
            for member in members {
                // Only the head will have this type
                if member.type == .Split_Head {
                    head = member
                } else {
                    newMembers.append(member)
                }
            }
            
            if head == nil {
                head = Transaction.newSplitTransaction()
            }
            
            return SplitTransactionForm(head: head!, splitMembers: newMembers, selectedBucket: contextBucket, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
        
        case .documentList(context: let context, transaction: let transaction):
            /*return DocumentListView(transaction: transaction).toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: { context.dismiss() })
                }
            }).padding().any()*/
            return EmptyView().any()
            
        case .confirmDelete(context: let context, message: _, onConfirm: let onConfirm):
            return VStack{
                Text("Are you sure you want to delete this?")
            }.toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { context.dismiss() })
                }
                ToolbarItem(placement: .destructiveAction){
                    Button("Confirm", action: { context.dismiss(); onConfirm() })
                }
            }).padding().any()
        
        case .confirmAction(context: let context, message: let message, onConfirm: let onConfirm, onCancel: let onCancel):
            return VStack{
                Text(message)
            }.toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: { context.dismiss(); onCancel() })
                }
                ToolbarItem(placement: .destructiveAction){
                    Button("Confirm", action: { context.dismiss(); onConfirm() })
                }
            }).padding().any()
        }
    }
}
