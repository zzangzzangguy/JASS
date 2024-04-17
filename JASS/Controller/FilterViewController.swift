//
//  FilterViewController.swift
//  JASS
//
//  Created by 김기현 on 4/17/24.
//

import Foundation
import UIKit
import Then


class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // 필터링 옵션을 저장할 프로퍼티
    var selectedOptions: [String] = []

    // 필터링 옵션 리스트
    let options = ["헬스", "필라테스", "수영", "복싱", "요가", "크로스핏", "격투기", "댄스", "골프", "테니스"]

    // 필터링 옵션을 표시할 테이블뷰
    let tableView = UITableView()

    // 적용 버튼
    let applyButton = UIButton(type: .system)

    // 필터링 옵션이 선택되었을 때 호출될 클로저
    var onApply: (([String]) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupApplyButton()
    }

    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -16).isActive = true

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    func setupApplyButton() {
        view.addSubview(applyButton)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        applyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        applyButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        applyButton.setTitle("Apply", for: .normal)
        applyButton.backgroundColor = .systemBlue
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.layer.cornerRadius = 8
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
    }

    @objc func applyButtonTapped() {
        onApply?(selectedOptions)
        dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]

        if selectedOptions.contains(options[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = options[indexPath.row]

        if let index = selectedOptions.firstIndex(of: selectedOption) {
            selectedOptions.remove(at: index)
        } else {
            selectedOptions.append(selectedOption)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
