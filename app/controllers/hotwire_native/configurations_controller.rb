# Regras de navegação lidas pelos apps Hotwire Native (iOS e Android) ao abrir.
# Formulários de cadastro e edição abrem como modal; as telas da barra de abas
# substituem a pilha em vez de empilhar uma tela nova a cada toque.
class HotwireNative::ConfigurationsController < ApplicationController
  allow_unauthenticated_access

  TAB_PATHS = %w[/ /membros /frota /rotas /auditoria /aluno /motorista/rota /motorista/rota/passageiros].freeze

  def show
    render json: {
      settings: {},
      rules: [
        { patterns: [ ".*" ], properties: { context: "default", pull_to_refresh_enabled: true } },
        { patterns: [ "/novo$", "/new$", "/editar$", "/edit$" ], properties: { context: "modal", pull_to_refresh_enabled: false } },
        { patterns: [ "/cadastro" ], properties: { context: "default", pull_to_refresh_enabled: false } },
        { patterns: [ "/motorista/viagem/qrcode$", "/aluno/checkin/qr$" ], properties: { context: "modal", pull_to_refresh_enabled: false } },
        { patterns: TAB_PATHS.map { |path| "^#{Regexp.escape(path)}$" }, properties: { presentation: "replace_root" } },
        { patterns: [ "/login$" ], properties: { context: "default", presentation: "replace_root", pull_to_refresh_enabled: false } }
      ]
    }
  end
end
