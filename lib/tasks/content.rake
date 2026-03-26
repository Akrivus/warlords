namespace :content do
  desc "Validate authored card definitions for shape and broken references"
  task validate_cards: :environment do
    report = Content::CardDefinitionsValidator.call(cards: CardDefinition.order(:scenario_key, :key).to_a)

    puts report.summary_line
    report.issues.each { |issue| puts issue.to_text }

    abort("Card content validation failed") unless report.success?
  end
end
