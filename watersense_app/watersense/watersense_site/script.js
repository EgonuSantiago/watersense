// Função para aplicar máscara de telefone
document.getElementById("telefone").addEventListener("input", function () {
    let tel = this.value.replace(/\D/g, ""); // Remove tudo que não é número

    if (tel.length <= 10) {
        this.value = tel.replace(/^(\d{2})(\d{4})(\d{0,4})/, "($1) $2-$3");
    } else {
        this.value = tel.replace(/^(\d{2})(\d{5})(\d{0,4})/, "($1) $2-$3");
    }
});

// Função para aplicar máscara de CEP
document.getElementById("cep").addEventListener("input", function () {
    let cep = this.value.replace(/\D/g, "");
    this.value = cep.replace(/^(\d{5})(\d{0,3})/, "$1-$2");
});

// Busca de endereço pelo CEP usando API ViaCEP
document.getElementById("cep").addEventListener("blur", function () {
    let cep = this.value.replace(/\D/g, '');
    if (cep.length !== 8) {
        alert("CEP inválido");
        return;
    }
    fetch(`https://viacep.com.br/ws/${cep}/json/`)
        .then(response => response.json())
        .then(data => {
            if (!data.erro) {
                document.getElementById("endereco").value = data.logradouro;
            } else {
                alert("CEP não encontrado");
            }
        })
        .catch(() => alert("Erro ao buscar o CEP"));
});

// Validação do formulário
document.getElementById("formCadastro").addEventListener("submit", function (e) {
    e.preventDefault();

    const email = document.getElementById("email").value;
    const telefone = document.getElementById("telefone").value;
    const senha = document.getElementById("senha").value;

    if (!email.includes("@") || !email.includes(".")) {
        alert("Digite um e-mail válido");
        return;
    }

    if (telefone.replace(/\D/g, "").length < 10) {
        alert("Digite um telefone válido");
        return;
    }

    if (senha.length < 6) {
        alert("A senha deve ter pelo menos 6 caracteres");
        return;
    }

    alert("Cadastro realizado com sucesso!");
    document.getElementById("formCadastro").reset();
    
});
