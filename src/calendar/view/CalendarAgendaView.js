//@flow
import m from "mithril"
import {CalendarEventBubble} from "./CalendarEventBubble"
import {incrementDate} from "@tutao/tutanota-utils"
import {styles} from "../../gui/styles"
import {lang} from "../../misc/LanguageViewModel"
import {formatDate, formatDateWithWeekday} from "../../misc/Formatter"
import {
	eventStartsBefore,
	formatEventTime,
	getEventColor,
	getStartOfDayWithZone,
	getTimeTextFormatForLongEvent,
	getTimeZone,
	hasAlarmsForTheUser
} from "../date/CalendarUtils"
import {isAllDayEvent} from "../../api/common/utils/CommonCalendarUtils"
import {neverNull} from "@tutao/tutanota-utils"
import {px, size} from "../../gui/size"
import {lastThrow} from "@tutao/tutanota-utils"
import type {CalendarEvent} from "../../api/entities/tutanota/CalendarEvent"
import {logins} from "../../api/main/LoginController"
import type {GroupColors} from "./CalendarView"
import type {CalendarEventBubbleClickHandler} from "./CalendarViewModel"

type Attrs = {
	/**
	 * maps start of day timestamp to events on that day
	 */
	eventsForDays: Map<number, Array<CalendarEvent>>,
	onEventClicked: CalendarEventBubbleClickHandler,
	groupColors: GroupColors,
	hiddenCalendars: $ReadOnlySet<Id>,
	onDateSelected: (date: Date) => mixed,
}

export class CalendarAgendaView implements MComponent<Attrs> {
	view({attrs}: Vnode<Attrs>): Children {
		const now = new Date()
		const zone = getTimeZone()

		const today = getStartOfDayWithZone(now, zone)
		const tomorrow = incrementDate(new Date(today), 1)
		const days = getNextFourteenDays(today)
		const lastDay = lastThrow(days)
		let title: string
		if (days[0].getMonth() === lastDay.getMonth()) {
			title = `${lang.formats.dateWithWeekdayWoMonth.format(days[0])} - ${lang.formats.dateWithWeekdayAndYear.format(lastDay)}`
		} else {
			title = `${lang.formats.dateWithWeekday.format(days[0])} - ${lang.formats.dateWithWeekdayAndYear.format(lastDay)}`
		}
		const lastDayFormatted = formatDate(lastDay)

		return m(".fill-absolute.flex.col.margin-are-inset-lr", [
				m(".mt-s.pr-l", [
					styles.isDesktopLayout() ?
						[
							m("h1.flex.row", {
								style: {
									"margin-left": px(size.calendar_hour_width)
								}
							}, [lang.get("agenda_label"), m(".ml-m.no-wrap.overflow-hidden", title)]),
							m("hr.hr.mt-s"),
						]
						: null,
				]),
				m(".scroll.pt-s", days
					.map((day: Date) => {
						let events = (attrs.eventsForDays.get(day.getTime())
							|| []).filter((e) => !attrs.hiddenCalendars.has(neverNull(e._ownerGroup)))
						if (day === today) {
							// only show future and currently running events
							events = events.filter(ev => isAllDayEvent(ev) || now < ev.endTime)
						} else if (day.getTime() > tomorrow.getTime() && events.length === 0) {
							return null
						}

						const dateDescription = day.getTime() === today.getTime()
							? lang.get("today_label")
							: day.getTime() === tomorrow.getTime()
								? lang.get("tomorrow_label")
								: formatDateWithWeekday(day)
						return m(".flex.mlr-l.calendar-agenda-row.mb-s.col", {
							key: day,
						}, [
							m("button.pb-s.b", {
								onclick: () => attrs.onDateSelected(new Date(day)),
							}, dateDescription),
							m(".flex-grow", {
								style: {
									"max-width": "600px",
								}
							}, events.length === 0
								? m(".mb-s", lang.get("noEntries_msg"))
								: events.map((ev) => {
									const startsBefore = eventStartsBefore(day, zone, ev)
									const timeFormat = getTimeTextFormatForLongEvent(ev, day, day, zone)

									return m(".darker-hover.mb-s", {key: ev._id}, m(CalendarEventBubble, {
										text: ev.summary,
										secondLineText: (timeFormat ? formatEventTime(ev, timeFormat) : "") + (ev.location ? ", "
											+ ev.location : ""),
										color: getEventColor(ev, attrs.groupColors),
										hasAlarm: !startsBefore && hasAlarmsForTheUser(logins.getUserController().user, ev),
										click: (domEvent) => attrs.onEventClicked(ev, domEvent),
										height: 38,
										verticalPadding: 2,
										fadeIn: true,
										opacity: 1,
										enablePointerEvents: true
									}))
								}))
						])
					})
					.filter(Boolean) // mithril doesn't allow mixing keyed elements with null (for perf reasons it seems)
					.concat(m(".mlr-l", {key: "events_until"}, lang.get("showingEventsUntil_msg", {"{untilDay}": lastDayFormatted}))))
			]
		)
	}
}

function getNextFourteenDays(startOfToday: Date): Array<Date> {
	let calculationDate = new Date(startOfToday)
	const days = []
	for (let i = 0; i < 14; i++) {
		days.push(new Date(calculationDate.getTime()))
		calculationDate = incrementDate(calculationDate, 1)
	}
	return days
}
