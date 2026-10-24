require "test_helper"
require "i18n/tasks"

class I18nTest < ActiveSupport::TestCase
  def setup
    @i18n = I18n::Tasks::BaseTask.new
  end

  def test_no_missing_keys
    missing_keys = @i18n.missing_keys

    assert_empty missing_keys,
                 "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
  end

  def test_no_unused_keys
    unused_keys = @i18n.unused_keys

    assert_empty unused_keys,
                 "#{unused_keys.leaves.count} unused i18n keys, run `i18n-tasks unused' to show them"
  end

  def test_no_untranslated_values
    untranslated = @i18n.eq_base_keys

    assert_empty untranslated,
                 "#{untranslated.leaves.count} values equal the English text, " \
                 "run `i18n-tasks eq-base' to show them, or add the key to ignore_eq_base"
  end

  # Proves eq_base_keys reports a copied English value and skips an allowlisted one.
  def test_allowlist_exempts_identical_values
    Dir.mktmpdir do |dir|
      File.write("#{dir}/en.yml", { "en" => { "save" => "Save", "same" => "Dashboard" } }.to_yaml)
      File.write("#{dir}/nl.yml", { "nl" => { "save" => "Save", "same" => "Dashboard" } }.to_yaml)
      task = I18n::Tasks::BaseTask.new(locales: %w[en nl], data: { read: [ "#{dir}/%{locale}.yml" ] },
                                       ignore_eq_base: { all: [ "same" ] })

      assert_equal %w[save], task.eq_base_keys.key_names(root: false).map { |key| key.delete_prefix("nl.") }
    end
  end

  # Proves a view that calls t with an unknown key raises instead of falling back.
  def test_missing_key_in_view_raises
    error = assert_raises ActionView::Template::Error do
      ApplicationController.render(inline: '<%= t("no.such.key") %>')
    end

    assert_kind_of I18n::MissingTranslationData, error.cause
  end

  def test_files_are_normalized
    non_normalized = @i18n.non_normalized_paths
    error_message = "The following files need to be normalized:\n" \
                    "#{non_normalized.map { |path| "  #{path}" }.join("\n")}\n" \
                    "Please run `i18n-tasks normalize' to fix"

    assert_empty non_normalized, error_message
  end

  def test_no_inconsistent_interpolations
    inconsistent_interpolations = @i18n.inconsistent_interpolations
    error_message = "#{inconsistent_interpolations.leaves.count} i18n keys have inconsistent interpolations.\n" \
                    "Please run `i18n-tasks check-consistent-interpolations' to show them"

    assert_empty inconsistent_interpolations, error_message
  end
end
