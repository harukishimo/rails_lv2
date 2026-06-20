module ApplicationHelper
  def status_badge(status, label: nil)
    tag.span(label || status.to_s.humanize, class: [ "status-badge", "status-badge--#{status}" ])
  end

  def error_summary(record)
    return if record.blank? || record.errors.blank?

    tag.div(class: "form-errors", role: "alert") do
      tag.h2("入力内容を確認してください", class: "form-errors__title") +
        tag.ul do
          safe_join(record.errors.full_messages.map { |message| tag.li(message) })
        end
    end
  end

  def empty_state(message)
    tag.div(message, class: "empty-state")
  end

  def nav_link(label, path)
    link_to label, path, class: "app-nav__link"
  end
end
