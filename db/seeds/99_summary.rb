puts <<~SUMMARY

  Seeds criados. Senha de todos: #{Seeds::PASSWORD}

  EMPRESA A - Transportes Escolares Ltda (São Paulo)
    dona@transportes.com                owner
    secretaria@transportes.com          manager
    motorista@transportes.com           motorista: ônibus 1 (seg-sex), ônibus reserva sem rota (sáb); SEM viagem ativa
    motorista2@transportes.com          motorista: ônibus 2 com VIAGEM ATIVA (ida)
    motorista.livre@transportes.com     motorista sem ônibus (estado vazio)
    aluno@transportes.com               ida e volta, ônibus 1
    bruno@transportes.com               só ida, ônibus 1
    carla@transportes.com               só volta, ônibus 1
    diego@transportes.com               ônibus 1, endereço sem localização ("sem parada definida")
    fabio@transportes.com               ônibus 2, viagem ativa e já embarcado
    gabi@transportes.com                ônibus 2, ida e volta
    elisa@transportes.com               sem ônibus (estado vazio)

  EMPRESA B - Viação Campinas Escolar (isolamento entre empresas)
    dono@campinas.com  secretaria@campinas.com  motorista@campinas.com  henrique@campinas.com

  SEM EMPRESA: novo.dono@transportes.com (cai no cadastro de empresa)

  Frota A: ABC1D23 (rota Jardins), DEF4G56 (rota Consolação), GHI7J89 (sem rota), JKL0M12 (inativo).
  Rota "Zona Sul" existe sem ônibus. Faculdade "UNITRI" existe nas duas empresas com o mesmo CEP.
SUMMARY
