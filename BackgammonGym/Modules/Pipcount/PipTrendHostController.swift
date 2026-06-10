//
//  PipTrendHostController.swift
//  BackgammonGym
//
//  Hosts the SwiftUI PipTrendChart and holds the two axes of choice as
//  state: which metric (hit rate / time) and which mode filter
//  (training / workout / both). The nav bar lets the user switch both.
//

import Foundation
import UIKit
import SwiftUI

@objc public class PipTrendHostController: UIViewController {

    // Current selection.
    private var metric: PipChartMetric = .percent
    private var modeFilter: String? = nil   // nil = both

    private var hostingController: UIHostingController<PipTrendChart>?

    @objc public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = "Trends"

        setupNavBar()
        embedChart()
    }

    // MARK: Nav bar

    private func setupNavBar() {
        let homeButton = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            style: .plain,
            target: self,
            action: #selector(homeTapped))

        let metricButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left.arrow.right"),
            style: .plain,
            target: self,
            action: #selector(toggleMetric))

        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped))

        // Mode filter as a pull-down menu.
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            menu: buildFilterMenu())

        homeButton.tintColor    = UIColor(named: "AccentColor")
        metricButton.tintColor  = UIColor(named: "AccentColor")
        shareButton.tintColor   = UIColor(named: "AccentColor")
        filterButton.tintColor  = UIColor(named: "AccentColor")

        self.navigationItem.leftBarButtonItem   = homeButton
        self.navigationItem.rightBarButtonItems = [shareButton, filterButton, metricButton]
    }

    private func buildFilterMenu() -> UIMenu {
        let both = UIAction(title: "Training & Workout",
                            state: modeFilter == nil ? .on : .off) { [weak self] _ in
            self?.modeFilter = nil
            self?.refresh()
        }
        let training = UIAction(title: "Training only",
                                state: modeFilter == "training" ? .on : .off) { [weak self] _ in
            self?.modeFilter = "training"
            self?.refresh()
        }
        let workout = UIAction(title: "Workout only",
                               state: modeFilter == "workout" ? .on : .off) { [weak self] _ in
            self?.modeFilter = "workout"
            self?.refresh()
        }
        return UIMenu(title: "Show", children: [both, training, workout])
    }

    // MARK: Chart embedding

    private func embedChart() {
        let chart = makeChart()
        let host = UIHostingController(rootView: chart)

        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
        self.hostingController = host
    }

    private func makeChart() -> PipTrendChart {
        let data = CoreDataManager.shared().sessionChartData(forMode: modeFilter)
        let title = (metric == .percent) ? "Hit rate" : "Average time"
        return PipTrendChart(
            title: title,
            metric: metric,
            sessions: data as [NSDictionary],
            greenSeconds:  BGGTimeColor.greenMax(),
            orangeSeconds: BGGTimeColor.orangeMax(),
            greenRate:     BGGTimeColor.rateGreenMin(),
            orangeRate:    BGGTimeColor.rateOrangeMin())
    }

    // Rebuild the SwiftUI view with the current state.
    private func refresh() {
        hostingController?.rootView = makeChart()
        setupNavBar()   // refresh menu checkmarks
    }

    // MARK: Actions

    @objc private func toggleMetric() {
        metric = (metric == .percent) ? .seconds : .percent
        refresh()
    }

    @objc private func homeTapped() {
        self.navigationController?.popToRootViewController(animated: true)
    }

    @objc private func shareTapped() {
        guard let image = captureView() else { return }
        let activityVC = UIActivityViewController(activityItems: [image],
                                                  applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.barButtonItem =
                self.navigationItem.rightBarButtonItems?.first
        }
        self.present(activityVC, animated: true)
    }

    private func captureView() -> UIImage? {
        guard let v = self.view else { return nil }
        UIGraphicsBeginImageContextWithOptions(v.bounds.size, false, 0.0)
        v.drawHierarchy(in: v.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
