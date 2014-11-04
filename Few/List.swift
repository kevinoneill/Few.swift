//
//  List.swift
//  Few
//
//  Created by Josh Abernathy on 10/5/14.
//  Copyright (c) 2014 Josh Abernathy. All rights reserved.
//

import Foundation
import AppKit

private var ElementKey = "ElementKey"

private let defaultRowHeight: CGFloat = 42

func indexOf<T: AnyObject>(array: [T], element: T) -> Int? {
	for (i, e) in enumerate(array) {
		if e === element { return i }
	}

	return nil
}

func objectsToIndexes<T: AnyObject>(whole: [T], some: [T]) -> NSIndexSet {
	return some.map { e in
		return indexOf(whole, e)
	}.reduce(NSMutableIndexSet(indexesInRange: NSMakeRange(0, 0))) { (set, index: Int?) in
		set.addIndex <^> index
		return set
	}
}

private class TableViewHandler: NSObject, NSTableViewDelegate, NSTableViewDataSource {
	let tableView: NSTableView

	var items: [Element] {
		didSet {
			let oldR = oldValue.map { RealizedElement(element: $0, view: nil) }
			let itemsR = items.map { RealizedElement(element: $0, view: nil) }
			let diff = diffElementLists(oldR, itemsR)
			if diff.add.count == 0 && diff.remove.count == 0 { return }

			let addIndexes = objectsToIndexes(itemsR, diff.add)
			let removeIndexes = objectsToIndexes(oldR, diff.remove)

			tableView.beginUpdates()
			tableView.insertRowsAtIndexes(addIndexes, withAnimation: .EffectNone)
			tableView.removeRowsAtIndexes(removeIndexes, withAnimation: .EffectNone)
			tableView.endUpdates()
		}
	}

	init(tableView: NSTableView, items: [Element]) {
		self.tableView = tableView
		self.items = items
		super.init()

		tableView.setDelegate(self)
		tableView.setDataSource(self)
	}

	deinit {
		tableView.setDelegate(nil)
		tableView.setDataSource(nil)
	}

	// MARK: NSTableViewDelegate

	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let element = items[row]
		var view: NSView?
		if let key = element.key {
			var listCell = tableView.makeViewWithIdentifier(key, owner: nil) as ListCell?
			if listCell == nil {
				let newListCell = ListCell(frame: CGRectZero)
				newListCell.identifier = key

				listCell = newListCell
			}

			listCell?.element = RealizedElement(element: element, view: nil)

			view = listCell
		} else {
			view = element.realize()
		}

		return view
	}

	func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		let height = NSHeight(items[row].frame)
		return height > CGFloat(0) ? height : defaultRowHeight
	}

	// MARK: NSTableViewDataSource

	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return items.count
	}
}

private class ListHostingScrollView: NSScrollView {
	var handler: TableViewHandler?
}

public class List: Element {
	private let items: [Element]

	public init(_ items: [Element]) {
		self.items = items
	}

	// MARK: -

	public override func applyDiff(view: ViewType, other: Element) {
		let otherList = other as List
		let scrollView = view as ListHostingScrollView

		super.applyDiff(view, other: other)

		scrollView.handler?.items = items
	}

	public override func realize() -> ViewType? {
		let scrollView = ListHostingScrollView(frame: frame)
		scrollView.hasVerticalScroller = true
		scrollView.borderType = .BezelBorder

		let tableView = NSTableView(frame: scrollView.bounds)

		let column = NSTableColumn(identifier: "ListColumn")
		column.width = tableView.bounds.size.width
		tableView.addTableColumn(column)

		tableView.headerView = nil

		scrollView.documentView = tableView

		scrollView.handler = TableViewHandler(tableView: tableView, items: items)

		return scrollView
	}
}