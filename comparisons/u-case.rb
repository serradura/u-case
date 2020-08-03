class CreateResponse < Micro::Case
  attributes :responder, :answers, :survey

  def call!
    survey_response = responder.survey_responses.build(
      response_text: answers[:text],
      rating: answers[:rating],
      survey: survey
    )

    return Success result: attributes(:responder, :survey) if survey_response.save

    Failure :survey_response_errors, result: survey_response.errors
  end
end

class AddRewardPoints < Micro::Case
  attributes :responder, :survey

  def call!
    reward_account = responder.reward_account
    reward_account.balance += survey.reward_points

    return Success, result: attributes if reward_account.save

    Failure :reward_account_errors, result: reward_account.errors
  end
end

class SendNotifications < Micro::Case
  attributes :responder, :survey

  def call!
    sender = survey.sender

    SurveyMailer.delay.notify_responder(responder.id)
    SurveyMailer.delay.notify_sender(sender.id)

    if sender.add_survey_response_notification
      Success, result: attributes(:survey)
    else
      Failure :sender_errors, result: sender.errors
    end
  end
end

class ReplyToSurvey < Micro::Case
  flow CreateResponse,
    AddRewardPoints,
    SendNotifications
end

# or

ReplyToSurvey = Micro::Cases.flow([
  CreateResponse,
  AddRewardPoints,
  SendNotifications
])
