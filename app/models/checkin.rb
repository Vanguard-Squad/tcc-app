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

  # As mesmas etapas, vistas por quem acompanha (gestão, motorista).
  EVENT_LABELS = {
    "boarded_initial" => "Embarcou no ponto",
    "disembarked_college" => "Chegou à faculdade",
    "boarded_college" => "Embarcou na faculdade",
    "disembarked_final" => "Desembarcou no ponto"
  }.freeze

  LEG_LABELS = {
    "outbound" => { waiting: "Aguardando embarque", boarded: "Embarcou", done: "Chegou à faculdade" },
    "return" => { waiting: "Aguardando embarque", boarded: "Embarcou", done: "Desembarcou no ponto" }
  }.freeze

  belongs_to :vehicle
  belongs_to :student

  # Aceita tanto o valor gravado ("return") quanto a chave do enum de Trip
  # ("return_trip"), que é o que `trip.direction` devolve.
  def self.steps_for(direction)
    STEPS_BY_DIRECTION.fetch(Trip.directions.fetch(direction.to_s, direction.to_s))
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

  def advance!(step, direction, at: Time.current)
    raise InvalidStep, "Etapa fora de ordem." unless step.to_s == next_step(direction)

    update!(step => at, status: step.to_s == STEPS.last)
  end

  # Horário informado pelo celular do aluno (check-in feito sem conexão e
  # reenviado depois). Só é aceito entre o início da viagem e agora; fora
  # disso, ou se vier inválido, vale o horário do servidor.
  def self.recorded_time(raw, trip:)
    time = Time.zone.iso8601(raw.to_s) rescue nil
    return Time.current unless time && time.between?(trip.started_at, Time.current)

    time
  end
end
