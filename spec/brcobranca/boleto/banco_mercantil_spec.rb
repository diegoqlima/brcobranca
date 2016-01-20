# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.describe Brcobranca::Boleto::Mercantil do
  before(:each) do
    @valid_attributes = {
      data_documento: Date.new(2012, 11, 15),
      data_vencimento: Date.new(2012, 11, 15),
      aceite: "N",
      valor: 1.00,
      local_pagamento: "nota_fiscal",
      cedente: "Thauan Zatta",
      documento_cedente: "00.981.069/000658",
      sacado: "Lésio Pinheiro",
      sacado_documento: "",
      agencia: "0165",
      conta_corrente: "25179",
      numero_documento: "82475",
      sacado_endereco: "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor"
    }
  end
  
  describe 'Busca logotipo do banco' do
    it_behaves_like 'busca_logotipo'
  end

  it "deve gerar nosso numero para o boleto com o digito verificador" do
    boleto_novo = Brcobranca::Boleto::Mercantil.new(@valid_attributes)
    expect(boleto_novo.nosso_numero_boleto).to eql("0000082475-4")
  end

  it "deve gerar numero de codigo de barras" do
    boleto_novo = Brcobranca::Boleto::Mercantil.new(@valid_attributes)
    expect(boleto_novo.codigo_barras.linha_digitavel_mercantil).to eql("38990.16509 00008.247546 00002.517928 1 55180000000100")
  end

  it "deve gerar codigo de barras mesmo que a conta corrente possua menos digitos" do
    @valid_attributes[:conta_corrente] = "25179"
    @valid_attributes[:numero_documento] = "82475"
    boleto_novo = Brcobranca::Boleto::Mercantil.new(@valid_attributes)
    expect(boleto_novo.codigo_barras.linha_digitavel_mercantil).to eql("38990.16509 00008.247546 00002.517928 1 55180000000100")
  end

  it "não deve gerar boleto com attributos invalidos" do
    @valid_attributes[:conta_corrente] = nil
    @valid_attributes[:agencia] = nil
    @valid_attributes[:numero_documento] = nil
    boleto_novo = Brcobranca::Boleto::Mercantil.new(@valid_attributes)
    expect(boleto_novo).not_to be_valid
  end
end
