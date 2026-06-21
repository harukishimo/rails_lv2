module ApplicationHelper
  def status_badge(status, label: nil)
    tag.span(label || label_for(status), class: status_badge_classes(status))
  end

  def error_summary(record)
    return if record.blank? || record.errors.blank?

    tag.div(class: ui_class(:form_errors), role: "alert") do
      tag.h2("入力内容を確認してください", class: ui_class(:form_errors_title)) +
        tag.ul do
          safe_join(record.errors.full_messages.map { |message| tag.li(message) })
        end
    end
  end

  def empty_state(message)
    tag.div(message, class: ui_class(:empty_state))
  end

  def nav_link(label, path)
    link_to label, path, class: ui_class(:nav_link)
  end

  def enum_label(model_class, enum_name, value)
    I18n.t(
      "activerecord.enums.#{model_class.model_name.i18n_key}.#{enum_name}.#{value}",
      default: label_for(value)
    )
  end

  def enum_options_for(model_class, enum_name)
    enum_values = model_class.public_send(enum_name.to_s.pluralize).keys
    enum_values.map { |value| [ enum_label(model_class, enum_name, value), value ] }
  end

  def label_for(value)
    I18n.t("labels.#{value}", default: value.to_s.humanize)
  end

  def status_transition_label(event)
    return label_for(event.to_status) if event.from_status.blank?

    "#{label_for(event.from_status)} → #{label_for(event.to_status)}"
  end

  def status_transition_message(event)
    return "#{label_for(event.to_status)}になりました" if event.from_status.blank?

    "#{label_for(event.from_status)}から#{label_for(event.to_status)}へ変更しました"
  end

  def button_classes(variant = :primary)
    base = "inline-flex min-h-10 items-center justify-center rounded-md border px-4 py-2 text-sm font-semibold no-underline transition focus:outline-none focus:ring-2"

    case variant
    when :secondary
      "#{base} border-blue-700 bg-white text-blue-700 hover:bg-blue-50 focus:ring-blue-200"
    when :danger
      "#{base} border-red-700 bg-red-700 text-white hover:bg-red-800 focus:ring-red-200"
    else
      "#{base} border-blue-700 bg-blue-700 text-white hover:bg-blue-800 focus:ring-blue-200"
    end
  end

  def link_button_classes
    "min-h-0 border-0 bg-transparent p-0 text-sm font-semibold text-blue-700 shadow-none hover:bg-transparent hover:text-blue-800"
  end

  def flash_classes(type)
    base = "mb-4 rounded-lg px-4 py-3 font-semibold"
    type.to_sym == :alert ? "#{base} bg-red-50 text-red-800" : "#{base} bg-emerald-50 text-emerald-800"
  end

  def ui_class(key)
    UI_CLASSES.fetch(key)
  end

  private

  UI_CLASSES = {
    app_header: "border-b border-slate-200 bg-white",
    app_header_inner: "mx-auto flex max-w-6xl flex-col gap-3 px-5 py-3 md:flex-row md:items-center md:gap-5",
    app_brand: "whitespace-nowrap text-base font-bold text-slate-950 no-underline",
    app_nav: "flex flex-1 flex-wrap gap-2",
    app_user: "flex items-center gap-3 text-sm text-slate-500",
    nav_link: "rounded-md px-3 py-1.5 text-sm font-medium text-slate-800 no-underline hover:bg-blue-50 hover:text-blue-800",
    app_main: "mx-auto max-w-6xl px-5 py-7 pb-12",
    page_header: "mb-5 flex flex-col gap-4 md:flex-row md:items-start md:justify-between",
    page_title: "m-0 text-2xl font-bold leading-tight text-slate-950 md:text-3xl",
    page_description: "mt-1.5 text-sm text-slate-500",
    eyebrow: "mb-1 text-xs font-bold uppercase tracking-normal text-slate-500",
    dashboard_hero: "mb-6 flex flex-col gap-5 rounded-lg border border-slate-200 bg-white p-6 shadow-sm md:flex-row md:items-start md:justify-between",
    dashboard_identity: "grid min-w-48 gap-1 text-slate-500",
    dashboard_grid: "mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3",
    panel: "mb-5 rounded-lg border border-slate-200 bg-white p-5 shadow-sm",
    auth_layout: "mx-auto mt-8 grid max-w-5xl grid-cols-1 gap-5 lg:grid-cols-[minmax(0,1.2fr)_minmax(280px,0.8fr)]",
    auth_form: "grid gap-4",
    checkbox_field: "inline-flex items-center gap-2 text-sm text-slate-500",
    demo_accounts: "mb-4 grid gap-3",
    toolbar: "mb-5 flex flex-wrap items-end gap-3 rounded-lg border border-slate-200 bg-white p-4 shadow-sm",
    field: "grid min-w-44 gap-1.5",
    form_actions: "mt-4 flex flex-wrap gap-3",
    actions: "mt-4 flex flex-wrap gap-3",
    header_actions: "mt-0 flex flex-wrap gap-3",
    table_wrap: "overflow-x-auto rounded-lg border border-slate-200 bg-white shadow-sm",
    detail_list: "grid grid-cols-1 gap-x-4 gap-y-3 rounded-lg border border-slate-200 bg-white p-5 md:grid-cols-[minmax(150px,220px)_1fr]",
    form_errors: "mb-4 rounded-lg border border-red-300 bg-red-50 px-4 py-3 text-red-800",
    form_errors_title: "mb-2 mt-0 text-base font-bold",
    empty_state: "rounded-lg border border-dashed border-slate-300 bg-white p-6 text-center text-slate-500",
    warning_box: "mb-4 rounded-md border-l-4 border-amber-600 bg-amber-50 px-4 py-3 text-amber-900",
    muted_text: "text-slate-500",
    mono_text: "font-mono text-sm text-slate-800"
  }.freeze

  SUCCESS_STATUSES = %w[active approved passed completed closed calendar_created approve].freeze
  WARNING_STATUSES = %w[
    returned schedule_requested interview_requested interview_scheduled reviewing review_approved requested
    examiner_assigned submitted return_to_candidate
  ].freeze
  DANGER_STATUSES = %w[rejected failed canceled reject].freeze

  def status_badge_classes(status)
    status = status.to_s
    base = "inline-flex min-h-6 items-center rounded-full px-2 py-0.5 text-sm font-bold"

    if SUCCESS_STATUSES.include?(status)
      "#{base} bg-emerald-100 text-emerald-800"
    elsif WARNING_STATUSES.include?(status)
      "#{base} bg-amber-100 text-amber-800"
    elsif DANGER_STATUSES.include?(status)
      "#{base} bg-red-100 text-red-800"
    else
      "#{base} bg-slate-100 text-slate-700"
    end
  end
end
