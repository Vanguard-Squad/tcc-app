class Checkin < ApplicationRecord
  class InvalidStep < StandardError; end

  STEPS = %w[boarded_initial disembarked_college boarded_college disembarked_final].freeze
  STEPS_BY_DIRECTION = { "outbound" => STEPS.first(2), "return" => STEPS.last(2) }.freeze

  STEP_LABELS = {
    "boarded_initial" => "Embarquei no ônibus",
    "disembarked_college" => "Cheguei na faculdade",
    "boarded_college" => "Embarquei na faculdade",
    "disembarked_final" => "Desembarquei no meu ponto"
  }.freeze

  LEG_LABELS = {
    "outbound" => { waiting: "Aguardando embarque", boarded: "Embarcou", done: "Chegou à faculdade" },
    "return" => { waiting: "Aguardando embarque", boarded: "Embarcou", done: "Desembarcou no ponto" }
  }.freeze

  belongs_to :vehicle
  belongs_to :student

  def self.steps_for(direction)
    STEPS_BY_DIRECTION.fetch(direction.to_s)
  end

  def self.today_for(student:, vehicle:)
    find_by(student: student, vehicle: vehicle, date: Time.current.beginning_of_day)
  end

  def self.today_for!(student:, vehicle:)
    find_or_create_by!(student: student, vehicle: vehicle, date: Time.current.beginning_of_day)
  end

  # Situação do aluno no trecho: aguardando, embarcado ou concluído, com a
  # hora do último registro do trecho.
  def leg_status(direction)
    first, last = self.class.steps_for(direction)

    if self[last] then [ :done, self[last] ]
    elsif self[first] then [ :boarded, self[first] ]
    else [ :waiting, nil ]
    end
  end

  def next_step(direction)
    self.class.steps_for(direction).find { |step| self[step].nil? }
  end

  def advance!(step, direction)
    raise InvalidStep, "Etapa fora de ordem." unless step.to_s == next_step(direction)

    update!(step => Time.current, status: step.to_s == STEPS.last)
  end
end
