import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:week_number/iso.dart';

import 'date_picker_mixin.dart';
import 'day_type.dart';
import 'i_selectable_picker.dart';
import 'styles/date_picker_styles.dart';
import 'styles/event_decoration.dart';
import 'styles/layout_settings.dart';
import 'utils.dart';

/// Widget for date pickers based on days and cover entire month.
/// Each cell of this picker is day.
class DayBasedPicker<T> extends StatefulWidget with CommonDatePickerFunctions {
  /// Selection logic.
  final ISelectablePicker selectablePicker;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// The earliest date the user is permitted to pick.
  /// (only year, month and day matter, time doesn't matter)
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  /// (only year, month and day matter, time doesn't matter)
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// The week whose days are displayed by this picker.
  final DateTime? displayedWeek;

  /// Layout settings what can be customized by user
  final DatePickerLayoutSettings datePickerLayoutSettings;

  ///  Key fo selected month (useful for integration tests)
  final Key? selectedPeriodKey;

  /// Styles what can be customized by user
  final DatePickerRangeStyles datePickerStyles;

  /// Builder to get event decoration for each date.
  ///
  /// For selected days all event styles are overridden by selected styles.
  final EventDecorationBuilder? eventDecorationBuilder;

  /// Localizations used to get strings for prev/next button tooltips,
  /// weekday headers and display values for days numbers.
  ///
  // ignore: comment_references
  /// If day headers builder is provided [datePickerStyles.dayHeaderBuilder]
  /// it will be used for building weekday headers instead of localizations.
  final MaterialLocalizations localizations;

  /// Creates main date picker view where every cell is day.
  DayBasedPicker({
    Key? key,
    required this.currentDate,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    required this.datePickerLayoutSettings,
    required this.datePickerStyles,
    required this.selectablePicker,
    required this.localizations,
    this.displayedWeek,
    this.selectedPeriodKey,
    this.eventDecorationBuilder,
  })  : assert(!firstDate.isAfter(lastDate)),
        super(key: key);

  @override
  State<DayBasedPicker<T>> createState() => _DayBasedPickerState<T>();
}

class _DayBasedPickerState<T> extends State<DayBasedPicker<T>> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.selectablePicker.onDayTapped(widget.currentDate);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> labels = <Widget>[];

    List<Widget> headers = _buildHeaders(widget.localizations, context);
    List<Widget> daysBeforeMonthStart =
        _buildCellsBeforeStart(widget.localizations);
    List<Widget> monthDays = _buildMonthCells(
      widget.localizations,
      widget.datePickerLayoutSettings,
      widget.datePickerStyles,
      widget.firstDate,
      widget.lastDate,
    );
    List<Widget> daysAfterMonthEnd = _buildCellsAfterEnd(widget.localizations);

    labels.addAll(headers);
    labels.addAll(daysBeforeMonthStart);
    labels.addAll(monthDays);
    labels.addAll(daysAfterMonthEnd);

    return Padding(
      padding: widget.datePickerLayoutSettings.contentPadding,
      child: Column(
        children: <Widget>[
          Flexible(
            child: GridView.custom(
              physics: widget.datePickerLayoutSettings.scrollPhysics,
              gridDelegate:
                  widget.datePickerLayoutSettings.dayPickerGridDelegate,
              childrenDelegate:
                  SliverChildListDelegate(labels, addRepaintBoundaries: false),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeaders(
    MaterialLocalizations localizations,
    BuildContext context,
  ) {
    final int firstDayOfWeekIndex =
        widget.datePickerStyles.firstDayOfeWeekIndex ??
            localizations.firstDayOfWeekIndex;

    DayHeaderStyleBuilder dayHeaderStyleBuilder =
        widget.datePickerStyles.dayHeaderStyleBuilder ??
            // ignore: avoid_types_on_closure_parameters
            (int i) => widget.datePickerStyles.dayHeaderStyle;

    final weekdayTitles = _getWeekdayTitles(context);
    List<Widget> headers = widget.getDayHeaders(
      dayHeaderStyleBuilder,
      weekdayTitles,
      firstDayOfWeekIndex,
    );

    return headers;
  }

  List<String> _getWeekdayTitles(BuildContext context) {
    final curLocale = Localizations.maybeLocaleOf(context) ?? _defaultLocale;

    // There is no access to weekdays full titles from [MaterialLocalizations]
    // so use intl to get it.
    final fullLocalizedWeekdayHeaders =
        intl.DateFormat.E(curLocale.toLanguageTag()).dateSymbols.WEEKDAYS;

    final narrowLocalizedWeekdayHeaders = widget.localizations.narrowWeekdays;

    final weekdayTitles =
        List.generate(fullLocalizedWeekdayHeaders.length, (dayOfWeek) {
      final builtHeader = widget.datePickerStyles.dayHeaderTitleBuilder
          ?.call(dayOfWeek, fullLocalizedWeekdayHeaders);
      final result = builtHeader ?? narrowLocalizedWeekdayHeaders[dayOfWeek];

      return result;
    });

    return weekdayTitles;
  }

  List<Widget> _buildCellsBeforeStart(MaterialLocalizations localizations) {
    List<Widget> result = [];

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;
    final int firstDayOfWeekIndex =
        widget.datePickerStyles.firstDayOfeWeekIndex ??
            localizations.firstDayOfWeekIndex;
    final int firstDayOffset =
        widget.computeFirstDayOffset(year, month, firstDayOfWeekIndex);

    final bool showDates = widget.datePickerLayoutSettings.showPrevMonthEnd;
    if (showDates) {
      int prevMonth = month - 1;
      if (prevMonth < 1) prevMonth = 12;
      int prevYear = prevMonth == 12 ? year - 1 : year;

      int daysInPrevMonth = DatePickerUtils.getDaysInMonth(prevYear, prevMonth);
      List<Widget> days = List.generate(firstDayOffset, (index) => index)
          .reversed
          .map((i) => daysInPrevMonth - i)
          .map((day) => _buildCell(prevYear, prevMonth, day))
          .toList();

      result = days;
    } else {
      result = List.generate(firstDayOffset, (_) => const SizedBox.shrink());
    }

    return result;
  }

  List<Widget> _buildMonthCells(
    MaterialLocalizations localizations,
    DatePickerLayoutSettings datePickerLayoutSettings,
    DatePickerStyles datePickerStyles,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    List<Widget> result = [];

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;
    final int daysInMonth = DatePickerUtils.getDaysInMonth(year, month);

    if (datePickerLayoutSettings.weekToDisplay != null &&
        widget.displayedWeek != null) {
      final DateTime dateFromWeekNumber = dateTimeFromWeekNumber(
          widget.displayedWeek!.year, datePickerLayoutSettings.weekToDisplay!);

      final DateTime newFirstDate = dateFromWeekNumber;

      for (int i = 1; i <= 7; i += 1) {
        Widget dayWidget = _buildCell(
          newFirstDate.year,
          newFirstDate.month,
          newFirstDate.day + i - 1,
        );
        result.add(dayWidget);
      }

      return result;
    }

    for (int i = 1; i <= daysInMonth; i += 1) {
      Widget dayWidget = _buildCell(year, month, i);
      result.add(dayWidget);
    }

    return result;
  }

  List<Widget> _buildCellsAfterEnd(MaterialLocalizations localizations) {
    List<Widget> result = [];
    final bool showDates = widget.datePickerLayoutSettings.showNextMonthStart;
    if (!showDates) return result;

    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;
    final int firstDayOfWeekIndex =
        widget.datePickerStyles.firstDayOfeWeekIndex ??
            localizations.firstDayOfWeekIndex;
    final int firstDayOffset =
        widget.computeFirstDayOffset(year, month, firstDayOfWeekIndex);
    final int daysInMonth = DatePickerUtils.getDaysInMonth(year, month);
    final int totalFilledDays = firstDayOffset + daysInMonth;

    int reminder = totalFilledDays % 7;
    if (reminder == 0) return result;
    final int emptyCellsNum = 7 - reminder;

    int nextMonth = month + 1;
    result = List.generate(emptyCellsNum, (i) => i + 1)
        .map((day) => _buildCell(year, nextMonth, day))
        .toList();

    return result;
  }

  Widget _buildCell(int year, int month, int day) {
    DateTime dayToBuild = DateTime(year, month, day);
    dayToBuild = _checkDateTime(dayToBuild);

    DayType dayType = widget.selectablePicker.getDayType(dayToBuild);

    Widget dayWidget = _DayCell(
      day: dayToBuild,
      currentDate: widget.currentDate,
      selectablePicker: widget.selectablePicker,
      datePickerStyles: widget.datePickerStyles,
      contentMargin: widget.datePickerLayoutSettings.cellContentMargin,
      eventDecorationBuilder: widget.eventDecorationBuilder,
      localizations: widget.localizations,
    );

    if (dayType != DayType.disabled) {
      dayWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.selectablePicker.onDayTapped(dayToBuild),
        child: dayWidget,
      );
    }

    return dayWidget;
  }

  // ignore: comment_references
  /// Checks if [DateTime] is same day as [lastDate] or [firstDate]
  // ignore: comment_references
  /// and returns dt corrected (with time of [lastDate] or [firstDate]).
  DateTime _checkDateTime(DateTime dt) {
    DateTime result = dt;

    // If dayToBuild is the first day we need to save original time for it.
    if (DatePickerUtils.sameDate(dt, widget.firstDate)) {
      result = widget.firstDate;
    }

    // If dayToBuild is the last day we need to save original time for it.
    if (DatePickerUtils.sameDate(dt, widget.lastDate)) result = widget.lastDate;

    return result;
  }
}

class _DayCell extends StatelessWidget {
  /// Day for this cell.
  final DateTime day;

  /// Selection logic.
  final ISelectablePicker selectablePicker;

  /// Styles what can be customized by user
  final DatePickerRangeStyles datePickerStyles;

  /// Margin of the cell content.
  final EdgeInsetsGeometry contentMargin;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Builder to get event decoration for each date.
  ///
  /// For selected days all event styles are overridden by selected styles.
  final EventDecorationBuilder? eventDecorationBuilder;

  final MaterialLocalizations localizations;

  const _DayCell({
    Key? key,
    required this.day,
    required this.selectablePicker,
    required this.datePickerStyles,
    required this.contentMargin,
    required this.currentDate,
    required this.localizations,
    this.eventDecorationBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DayType dayType = selectablePicker.getDayType(day);

    BoxDecoration? decoration;
    TextStyle? itemStyle;

    if (dayType != DayType.disabled && dayType != DayType.notSelected) {
      itemStyle = _getSelectedTextStyle(dayType);
      decoration = _getSelectedDecoration(dayType);
    } else if (dayType == DayType.disabled) {
      itemStyle = datePickerStyles.disabledDateStyle;
    } else if (DatePickerUtils.sameDate(currentDate, day)) {
      itemStyle = datePickerStyles.currentDateStyle;
    } else {
      itemStyle = datePickerStyles.defaultDateTextStyle;
    }

    // Merges decoration and textStyle with [EventDecoration].
    //
    // Merges only in cases if [dayType] is
    // DayType.notSelected or DayType.disabled.
    //
    // If day is current day it is also gets event decoration
    // instead of decoration for current date.
    if ((dayType == DayType.notSelected || dayType == DayType.disabled) &&
        eventDecorationBuilder != null) {
      EventDecoration? eDecoration = eventDecorationBuilder != null
          ? eventDecorationBuilder!.call(day)
          : null;

      decoration = eDecoration?.boxDecoration ?? decoration;
      itemStyle = eDecoration?.textStyle ?? itemStyle;
    }

    String semanticLabel = '${localizations.formatDecimal(day.day)}, '
        '${localizations.formatFullDate(day)}';

    bool daySelected =
        dayType != DayType.disabled && dayType != DayType.notSelected;

    Widget dayWidget = Container(
      margin: contentMargin,
      decoration: decoration,
      child: Center(
        child: Semantics(
          // We want the day of month to be spoken first irrespective of the
          // locale-specific preferences or TextDirection. This is because
          // an accessibility user is more likely to be interested in the
          // day of month before the rest of the date, as they are looking
          // for the day of month. To do that we prepend day of month to the
          // formatted full date.
          label: semanticLabel,
          selected: daySelected,
          child: ExcludeSemantics(
            child: Text(localizations.formatDecimal(day.day), style: itemStyle),
          ),
        ),
      ),
    );

    return dayWidget;
  }

  BoxDecoration? _getSelectedDecoration(DayType dayType) {
    BoxDecoration? result;

    if (dayType == DayType.single) {
      result = datePickerStyles.selectedSingleDateDecoration;
    } else if (dayType == DayType.start) {
      result = datePickerStyles.selectedPeriodStartDecoration;
    } else if (dayType == DayType.end) {
      result = datePickerStyles.selectedPeriodLastDecoration;
    } else {
      result = datePickerStyles.selectedPeriodMiddleDecoration;
    }

    return result;
  }

  TextStyle? _getSelectedTextStyle(DayType dayType) {
    TextStyle? result;

    if (dayType == DayType.single) {
      result = datePickerStyles.selectedDateStyle;
    } else if (dayType == DayType.start) {
      result = datePickerStyles.selectedPeriodStartTextStyle;
    } else if (dayType == DayType.end) {
      result = datePickerStyles.selectedPeriodEndTextStyle;
    } else {
      result = datePickerStyles.selectedPeriodMiddleTextStyle;
    }

    return result;
  }
}

Locale _defaultLocale = const Locale('en', 'US');
