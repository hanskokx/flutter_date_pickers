import 'dart:async';

import 'package:flutter/material.dart';

import 'day_based_changable_picker.dart';
import 'utils.dart';

/// Presenter for [DayBasedChangeablePicker] to handle month changes.
class DayBasedChangeablePickerPresenter {
  /// First date user can select.
  final DateTime firstDate;

  /// Last date user can select.
  final DateTime lastDate;

  /// Localization.
  final MaterialLocalizations localizations;

  /// If empty day cells before 1st day of showing month should be filled with
  /// date from the last week of the previous month.
  final bool showPrevMonthDates;

  /// If empty day cells after last day of showing month should be filled with
  /// date from the first week of the next month.
  final bool showNextMonthDates;

  /// Index of the first day in week.
  /// 0 is Sunday, 6 is Saturday.
  final int firstDayOfWeekIndex;

  /// View model stream for the [DayBasedChangeablePicker].
  Stream<DayBasedChangeablePickerState> get data => _controller.stream;

  /// Last view model state of the [DayBasedChangeablePicker].
  DayBasedChangeablePickerState? get lastVal => _lastVal;

  /// Creates presenter to use for [DayBasedChangeablePicker].
  DayBasedChangeablePickerPresenter(
      {required this.firstDate,
      required this.lastDate,
      required this.localizations,
      required this.showPrevMonthDates,
      required this.showNextMonthDates,
      int? firstDayOfWeekIndex})
      : firstDayOfWeekIndex =
            firstDayOfWeekIndex ?? localizations.firstDayOfWeekIndex;

  /// Update state according to the [selectedDate] if it needs.
  void setSelectedDate(DateTime selectedDate) {
    // bool firstAndLastNotNull = _firstShownDate != null
    //     && _lastShownDate != null;
    //
    // bool selectedOnCurPage =  firstAndLastNotNull
    //     && !selectedDate.isBefore(_firstShownDate)
    //     && !selectedDate.isAfter(_lastShownDate);
    // if (selectedOnCurPage) return;

    changeMonth(selectedDate);
  }

  /// Update state to show previous month.
  void gotoPrevMonth() {
    DateTime oldCur = _lastVal!.currentMonth;
    DateTime newCurDate = DateTime(oldCur.year, oldCur.month - 1);

    changeMonth(newCurDate);
  }

  /// Update state to show next month.
  void gotoNextMonth() {
    DateTime oldCur = _lastVal!.currentMonth;
    DateTime newCurDate = DateTime(oldCur.year, oldCur.month + 1);

    changeMonth(newCurDate);
  }

  /// Update state to change month to the [newMonth].
  void changeMonth(DateTime newMonth) {
    bool sameMonth = _lastVal != null &&
        DatePickerUtils.sameMonth(_lastVal!.currentMonth, newMonth);
    if (sameMonth) return;

    int monthPage = DatePickerUtils.monthDelta(firstDate, newMonth);
    DateTime prevMonth =
        DatePickerUtils.addMonthsToMonthDate(firstDate, monthPage - 1);

    DateTime curMonth =
        DatePickerUtils.addMonthsToMonthDate(firstDate, monthPage);

    DateTime nextMonth =
        DatePickerUtils.addMonthsToMonthDate(firstDate, monthPage + 1);

    String prevMonthStr = localizations.formatMonthYear(prevMonth);
    String curMonthStr = localizations.formatMonthYear(curMonth);
    String nextMonthStr = localizations.formatMonthYear(nextMonth);

    bool isFirstMonth = DatePickerUtils.sameMonth(curMonth, firstDate);
    bool isLastMonth = DatePickerUtils.sameMonth(curMonth, lastDate);

    String? prevTooltip = isFirstMonth
        ? null
        : "${localizations.previousMonthTooltip} $prevMonthStr";

    String? nextTooltip =
        isLastMonth ? null : "${localizations.nextMonthTooltip} $nextMonthStr";

    DayBasedChangeablePickerState newState = DayBasedChangeablePickerState(
      currentMonth: curMonth,
      currentWeek: curMonth,
      curMonthDis: curMonthStr,
      prevMonthDis: prevMonthStr,
      nextMonthDis: nextMonthStr,
      prevTooltip: prevTooltip,
      nextTooltip: nextTooltip,
      isFirstMonth: isFirstMonth,
      isLastMonth: isLastMonth,
      isFirstWeek: isFirstMonth,
      isLastWeek: isLastMonth,
    );

    _updateState(newState);
  }

  /// Update state to change week to the [newWeek].
  void changeWeek(DateTime initialDate, DateTime newWeek) {
    DateTime previousWeek = _lastVal?.currentWeek ?? initialDate;

    final bool lastValIsMoreThanAWeekAgo =
        previousWeek.difference(initialDate).abs().inDays >
            DateTime.daysPerWeek;

    if (lastValIsMoreThanAWeekAgo) {
      previousWeek =
          initialDate.subtract(Duration(days: DateTime.daysPerWeek + 1));
    }

    int weekPage = DatePickerUtils.weekDelta(firstDate, newWeek);

    DateTime curWeek = DatePickerUtils.addWeeksToWeekDate(firstDate, weekPage);

    final bool sameWeek = DatePickerUtils.sameWeek(previousWeek, newWeek);
    if (sameWeek) return;

    DateTime nextWeek = DatePickerUtils.addWeeksToWeekDate(curWeek, 1);

    String prevMonthStr = localizations.formatMonthYear(previousWeek);
    String curMonthStr = localizations.formatMonthYear(curWeek);
    String nextMonthStr = localizations.formatMonthYear(nextWeek);

    bool isFirstWeek = DatePickerUtils.sameWeek(curWeek, firstDate);
    bool isLastWeek = DatePickerUtils.sameWeek(curWeek, lastDate);

    bool isFirstMonth = DatePickerUtils.sameMonth(curWeek, firstDate);
    bool isLastMonth = DatePickerUtils.sameMonth(curWeek, lastDate);

    String? prevTooltip = isFirstWeek
        ? null
        : "${localizations.previousMonthTooltip} $prevMonthStr";

    String? nextTooltip =
        isLastWeek ? null : "${localizations.nextMonthTooltip} $nextMonthStr";

    DayBasedChangeablePickerState newState = DayBasedChangeablePickerState(
      currentMonth: curWeek,
      currentWeek: curWeek,
      curMonthDis: curMonthStr,
      prevMonthDis: prevMonthStr,
      nextMonthDis: nextMonthStr,
      prevTooltip: prevTooltip,
      nextTooltip: nextTooltip,
      isFirstMonth: isFirstMonth,
      isLastMonth: isLastMonth,
      isFirstWeek: isFirstWeek,
      isLastWeek: isLastWeek,
    );

    _updateState(newState);
  }

  /// Closes controller.
  void dispose() {
    _controller.close();
  }

  void _updateState(DayBasedChangeablePickerState newState) {
    _lastVal = newState;
    _controller.add(newState);
  }

  final StreamController<DayBasedChangeablePickerState> _controller =
      StreamController.broadcast();

  DayBasedChangeablePickerState? _lastVal;
}

/// View Model for the [DayBasedChangeablePicker].
class DayBasedChangeablePickerState {
  /// Display name of the current month.
  final String curMonthDis;

  /// Display name of the previous month.
  final String prevMonthDis;

  /// Display name of the next month.
  final String nextMonthDis;

  /// Tooltip for the previous month icon.
  final String? prevTooltip;

  /// Tooltip for the next month icon.
  final String? nextTooltip;

  /// Tooltip for the current month icon.
  final DateTime currentMonth;

  /// Tooltip for the current week icon.
  final DateTime currentWeek;

  /// If selected month is the month contains last date user can select.
  final bool isLastMonth;

  /// If selected month is the month contains first date user can select.
  final bool isFirstMonth;

  /// If selected week is the week contains last date user can select.
  final bool isLastWeek;

  /// If selected week is the week contains first date user can select.
  final bool isFirstWeek;

  /// Creates view model for the [DayBasedChangeablePicker].
  DayBasedChangeablePickerState({
    required this.curMonthDis,
    required this.prevMonthDis,
    required this.nextMonthDis,
    required this.currentMonth,
    required this.currentWeek,
    required this.isLastMonth,
    required this.isFirstMonth,
    required this.isLastWeek,
    required this.isFirstWeek,
    this.prevTooltip,
    this.nextTooltip,
  });
}
