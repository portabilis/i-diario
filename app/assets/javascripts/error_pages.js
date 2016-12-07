FreshWidget.init("", {
    "queryString": "&searchArea=no&widgetType=popup&formTitle=Suporte+ao+Usu%C3%A1rio+Portabilis&submitThanks=Obrigado%2C+j%C3%A1+registramos+sua+solicita%C3%A7%C3%A3o.+Em+breve+entraremos+em+contato.",
    "widgetType": "popup",
    "buttonType": "text",
    "buttonText": "Precisa de ajuda? Clique aqui",
    "buttonColor": "white",
    "buttonBg": "#004c93",
    "alignment": "3",
    "offset": "-2000px",
    "submitThanks": "Obrigado, já registramos sua solicitação. Em breve entraremos em contato.",
    "formHeight": "500px",
    "url": "https://portabilis.freshdesk.com"
});

document.getElementsByClassName("error-page-support-button")[0].onclick = function() {
  FreshWidget.show();
  return false;
}