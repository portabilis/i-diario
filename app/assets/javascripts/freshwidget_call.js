var entity = window.location.hostname

if (entity.match(/jacarei/)) {
  FreshWidget.init("",
      {"queryString": "&widgetType=popup&formTitle=Suporte+ao+Usu%C3%A1rio&submitTitle=Enviar&submitThanks=Obrigado%2C+j%C3%A1+registramos+sua+solicita%C3%A7%C3%A3o.+Em+breve+entraremos+em+contato.&searchArea=no",
      "utf8": "✓",
      "widgetType": "popup",
      "buttonType": "text",
      "buttonText": "Precisa de ajuda? Clique aqui",
      "buttonColor": "white",
      "buttonBg": "#0ac336",
      "alignment": "3",
      "offset": "235px",
      "submitThanks": "Obrigado, já registramos sua solicitação. Em breve entraremos em contato.",
      "formHeight": "500px",
      "url": "https://***REMOVED***brasil.freshdesk.com"}
  );
} else {
  FreshWidget.init("", {
      "queryString": "&widgetType=popup&submitTitle=Enviar+solicitação",
      "utf8": "✓",
      "widgetType": "popup",
      "buttonType": "text",
      "buttonText": "Precisa de ajuda? Clique aqui",
      "buttonColor": "white",
      "buttonBg": "#0ac336",
      "alignment": "3",
      "offset": "235px",
      "formHeight": "500px",
      "url": "https://portabilis.freshdesk.com"
  });
}
