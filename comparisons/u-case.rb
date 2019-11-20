class CreateResponse < Micro::Case
  attributes :responder, :answers, :survey

  def call!
    survey_response = responder.survey_responses.build(
      response_text: answers[:text],
      rating: answers[:rating],
      survey: survey
    )

    return Success { attributes(:responder, :survey) } if survey_response.save

    Failure(:survey_response_errors) { survey_response.errors }
  end
end

class AddRewardPoints < Micro::Case
  attributes :responder, :survey

  def call!
    reward_account = responder.reward_account
    reward_account.balance += survey.reward_points

    return Success { attributes(:responder, :survey) } if reward_account.save

    Failure(:reward_account_errors) { reward_account.errors }
  end
end

class SendNotifications < Micro::Case
  attributes :responder, :survey

  def call!
    sender = survey.sender

    SurveyMailer.delay.notify_responder(responder.id)
    SurveyMailer.delay.notify_sender(sender.id)

    return Success { attributes(:survey) } if sender.add_survey_response_notification

    Failure(:sender_errors) { sender.errors }
  end
end

ReplyToSurvey = CreateResponse >> AddRewardPoints >> SendNotifications

# or

ReplyToSurvey = Micro::Case::Flow([
  CreateResponse,
  AddRewardPoints,
  SendNotifications
])

# or

class ReplyToSurvey
  include Micro::Case::Flow

  flow CreateResponse, AddRewardPoints, SendNotifications
end
