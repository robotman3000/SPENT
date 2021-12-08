//
//  UIForms.swift
//  macOS
//
//  Created by Eric Nims on 7/22/21.
//

import SwiftUI
import SwiftUIKit

enum FormKeys: SheetProvider {
    case account(context: SheetContext, account: Bucket?)
    case bucket(context: SheetContext, bucket: Bucket?, parent: Bucket?)
    case transaction(context: SheetContext, transaction: Transaction?, contextBucket: Int64?)
    case transfer(context: SheetContext, transaction: Transaction?, contextBucket: Int64?)
    case tag(context: SheetContext, tag: Tag?)
    //case schedule(context: SheetContext, schedule: Schedule?, onSubmit: (_ data: inout Schedule) -> Void)
    case transactionTags(context: SheetContext, transaction: Transaction)
    case splitTransaction(context: SheetContext, splitHead: Transaction?, contextBucket: Int64?)
    case transactionTemplate(context: SheetContext, template: DBTransactionTemplate?)
    case documentList(context: SheetContext, transaction: Transaction)
    case confirmDelete(context: SheetContext, message: String, onConfirm: () -> Void)
    case confirmAction(context: SheetContext, message: String, onConfirm: () -> Void, onCancel: () -> Void)
    
    var sheet: AnyView {
        switch self {
        case .account(context: let context, account: var account):
            if account == nil{
                account = Bucket.newBucket()
            }
            return AccountForm(model: AccountFormModel(bucket: account!),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .bucket(context: let context, bucket: var bucket, parent: let parent):
            if bucket == nil{
                bucket = Bucket.newBucket()
            }
            return BucketForm(model: BucketFormModel(bucket: bucket!, parent: parent),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .transaction(context: let context, transaction: var transaction, contextBucket: let bucket):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            let model = TransactionFormModel(transaction: transaction!, contextBucket: bucket)
            return TransactionForm(model: model,
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .transfer(context: let context, transaction: var transaction, contextBucket: let bucket):
            if transaction == nil {
                transaction = Transaction.newTransaction()
            }
            let model = TransferFormModel(transaction: transaction!, contextBucket: bucket)
            return TransferForm(model: model,
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .tag(context: let context, tag: var tag):
            if tag == nil {
                tag = Tag.newTag()
            }
            return TagForm(model: TagFormModel(tag: tag!),
                           onSubmit: { context.dismiss() }, onCancel: { context.dismiss() } ).any()
            
//        case .schedule(context: let context, schedule: var schedule, onSubmit: let handleSubmit):
//            if schedule == nil {
//                schedule = Schedule.newSchedule()
//            }
//            return EmptyView().any()
//            //return ScheduleForm(schedule: schedule!, onSubmit: handleSubmit, onCancel: { context.dismiss() }).padding().any()
            
        case .transactionTags(context: let context, transaction: let transaction):
            return TransactionTagForm(model: TransactionTagFormModel(transaction: transaction),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .transactionTemplate(context: let context, template: var template):
            if template == nil {
                template = DBTransactionTemplate.newTemplate()
            }
            return TemplateForm(model: TemplateFormModel(template: template!),
                                onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
            
        case .splitTransaction(context: let context, splitHead: var head, contextBucket: let bucket):
            if head == nil {
                head = Transaction.newSplitTransaction()
            }
            return SplitTransactionForm(model: SplitTransactionFormModel(head: head!, contextBucket: bucket), onSubmit: { context.dismiss() }, onCancel: { context.dismiss() }).any()
        
        case .documentList(context: let context, transaction: let transaction):
            return DocumentListView(transaction: transaction).toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: { context.dismiss() })
                }
            }).padding().any()

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
