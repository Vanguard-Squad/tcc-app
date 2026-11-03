require "prawn"

# As fontes embutidas do PDF cobrem os acentos do português (Windows-1252).
Prawn::Fonts::AFM.hide_m17n_warning = true

# PDF do contrato de transporte, preenchido com os dados do aluno e da
# empresa. É este arquivo que o aluno assina pelo gov.br.
class Contract::Document
  def initialize(contract)
    @contract = contract
    @student = contract.student
    @user = @student.user
    @company = @user.company
  end

  def filename
    "contrato-transporte-#{@user.name.parameterize}.pdf"
  end

  def render
    Prawn::Document.new(page_size: "A4", margin: 56, info: { Title: "Contrato de prestação de serviço de transporte" }) do |pdf|
      pdf.font_size 11
      pdf.text "CONTRATO DE PRESTAÇÃO DE SERVIÇO DE TRANSPORTE UNIVERSITÁRIO", size: 14, style: :bold, align: :center
      pdf.move_down 6
      pdf.text "Nº #{@contract.id.to_s.rjust(6, "0")}", align: :center, color: "555555"
      pdf.move_down 24

      section(pdf, "1. Das partes")
      paragraph(pdf, "<b>CONTRATADA:</b> #{h(@company.name)}, inscrita no CNPJ sob o nº #{h(@company.cnpj)}, com sede em #{h(@company.address.label_with_city)}.")
      paragraph(pdf, "<b>CONTRATANTE:</b> #{h(@user.name)}, inscrito(a) no CPF sob o nº #{h(@student.cpf)}#{birthdate}, residente em #{h(@student.address.label_with_city)}, e-mail #{h(@user.email)}.")

      section(pdf, "2. Do objeto")
      paragraph(pdf, "O presente contrato tem por objeto a prestação de serviço de transporte do(a) CONTRATANTE entre o ponto de embarque mais próximo de sua residência e a instituição de ensino #{h(@student.college.name)}, situada em #{h(@student.college.address.label_with_city)}, nos dias e horários definidos pela CONTRATADA.")

      section(pdf, "3. Das obrigações da contratada")
      paragraph(pdf, "a) Manter os veículos em boas condições de conservação, segurança e higiene, com motoristas devidamente habilitados;")
      paragraph(pdf, "b) Cumprir os itinerários e horários informados no sistema, comunicando com antecedência qualquer alteração;")
      paragraph(pdf, "c) Tratar os dados pessoais do(a) CONTRATANTE conforme a Lei nº 13.709/2018 (LGPD), utilizando-os apenas para a execução deste contrato.")

      section(pdf, "4. Das obrigações do(a) contratante")
      paragraph(pdf, "a) Estar no ponto de embarque no horário combinado e registrar no sistema o embarque e o desembarque;")
      paragraph(pdf, "b) Zelar pelo veículo e respeitar o motorista e os demais passageiros;")
      paragraph(pdf, "c) Manter seus dados cadastrais atualizados junto à CONTRATADA.")

      section(pdf, "5. Da localização e do registro de viagens")
      paragraph(pdf, "O(A) CONTRATANTE declara estar ciente de que o sistema registra os horários de embarque e desembarque e exibe a localização do veículo durante as viagens, para fins de segurança e controle do serviço.")

      section(pdf, "6. Da vigência e rescisão")
      paragraph(pdf, "Este contrato vigora a partir da data de sua assinatura, por prazo indeterminado, podendo ser rescindido por qualquer das partes mediante comunicação prévia de 30 (trinta) dias.")

      section(pdf, "7. Da assinatura")
      paragraph(pdf, "As partes reconhecem a validade da assinatura eletrônica avançada realizada pelo portal gov.br, nos termos da Lei nº 14.063/2020.")

      pdf.move_down 16
      pdf.text "#{@company.address.city}, #{I18n.l(Date.current, format: :long)}.", align: :right
      pdf.move_down 48
      signature_line(pdf, @user.name, "CONTRATANTE — CPF #{@student.cpf}")

      pdf.number_pages "Página <page> de <total>", at: [ pdf.bounds.right - 120, -16 ], width: 120, align: :right, size: 8, color: "777777"
    end.render
  end

  private
    # Os parágrafos usam inline_format; dados digitados não podem virar marcação.
    def h(value)
      ERB::Util.html_escape(value.to_s)
    end

    def birthdate
      ", nascido(a) em #{I18n.l(@student.birthdate)}" if @student.birthdate
    end

    def section(pdf, title)
      pdf.move_down 8
      pdf.text title, style: :bold, size: 12
      pdf.move_down 4
    end

    def paragraph(pdf, text)
      pdf.text text, inline_format: true, align: :justify, leading: 2
      pdf.move_down 4
    end

    def signature_line(pdf, name, caption)
      pdf.stroke_horizontal_line pdf.bounds.width * 0.2, pdf.bounds.width * 0.8
      pdf.move_down 4
      pdf.text name, align: :center, style: :bold
      pdf.text caption, align: :center, size: 9, color: "555555"
    end
end
