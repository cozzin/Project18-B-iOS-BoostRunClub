//
//  ActivityProvider.swift
//  BoostRunClub
//
//  Created by 김신우 on 2020/12/06.
//

import CoreData
import Foundation

protocol ActivityWritable {
    func addActivity(activity: Activity, activityDetail: ActivityDetail, splits: [RunningSplit])
    func editActivity(activity: Activity)
}

protocol ActivityReadable {
    func fetchActivities() -> [Activity]
    func fetchActivityDetail(activityId: UUID) -> ActivityDetail?
    func fetchSplits(activityId: UUID) -> [RunningSplit]
}

protocol ActivityManageable {
    var reader: ActivityReadable { get }
    var writer: ActivityWritable { get }
}

class ActivityProvider: ActivityWritable, ActivityReadable {
    let coreDataService: CoreDataServiceable

    init(coreDataService: CoreDataServiceable) {
        self.coreDataService = coreDataService
    }

    func addActivity(activity: Activity, activityDetail: ActivityDetail, splits: [RunningSplit]) {
        ZActivity(context: coreDataService.context, activity: activity)
        ZActivityDetail(context: coreDataService.context, activityDetail: activityDetail)
        splits.forEach { ZRunningSplit(context: coreDataService.context, runningSplit: $0) }

        do {
            try coreDataService.context.save()
        } catch {
            print(error.localizedDescription)
        }

        // test
        fetchActivities().forEach {
            print($0.distance)
            let detail = fetchActivityDetail(activityId: $0.uuid!)
            print(detail?.calorie)
            print(detail?.locations.count)
            print(detail?.locations)
            let splits = fetchSplits(activityId: $0.uuid!)
            print(splits.count)
            splits.forEach { print($0.avgPace); print($0.runningSlices) }
        }
    }

    func editActivity(activity _: Activity) {}

    func fetchActivities() -> [Activity] {
        let request = NSFetchRequest<ZActivity>(entityName: "ZActivity")

        do {
            let result = try coreDataService.context.fetch(request)
            return result.map { $0.activity }
        } catch {
            print(error.localizedDescription)
        }
        return []
    }

    func fetchActivityDetail(activityId: UUID) -> ActivityDetail? {
        let request: NSFetchRequest<ZActivityDetail> = ZActivityDetail.fetchRequest(activityId: activityId)
        do {
            let result = try coreDataService.context.fetch(request)
            return result.map { $0.activityDetail }.first
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

    func fetchSplits(activityId: UUID) -> [RunningSplit] {
        let request: NSFetchRequest<ZRunningSplit> = ZRunningSplit.fetchRequest(activityId: activityId)
        do {
            let result = try coreDataService.context.fetch(request)
            return result.map { $0.runningSplit }
        } catch {
            print(error.localizedDescription)
        }
        return []
    }
}

extension ActivityProvider: ActivityManageable {
    var reader: ActivityReadable { self }
    var writer: ActivityWritable { self }
}