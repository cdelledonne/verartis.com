// https://www.javascripttutorial.net/javascript-dom/javascript-form/

const form = document.getElementById('contact-form');

if (form !== null) {

    function isFieldValid(field) {
        return (field.value.trim() !== '');
    }

    form.addEventListener('submit', (event) => {
        event.preventDefault();

        let formError = document.getElementById('contact-form-error');
        let elements = form.elements;

        // Data
        let firstName = elements['first_name'];
        let lastName = elements['last_name'];
        let emailAddress = elements['email_address'];
        let message = elements['message'];

        // Metadata
        let hcaptcha = elements['h-captcha-response'];
        let origin = elements['_origin'];
        let nextOnSuccess = elements['_next_on_success'];
        let nextOnFailure = elements['_next_on_failure'];

        // Data validation
        let firstNameValid = isFieldValid(firstName);
        let lastNameValid = isFieldValid(lastName);
        let emailAddressValid = isFieldValid(emailAddress);
        let messageValid = isFieldValid(message);
        let hcaptchaValid = isFieldValid(hcaptcha);
        let originValid = isFieldValid(origin);
        let nextOnSuccessValid = isFieldValid(nextOnSuccess);
        let nextOnFailureValid = isFieldValid(nextOnFailure);

        if (firstNameValid && lastNameValid && emailAddressValid && messageValid &&
            hcaptchaValid && originValid && nextOnSuccessValid && nextOnFailureValid) {
            formError.classList.add('d-none');
            form.submit();
        } else {
            formError.classList.remove('d-none');
        }
    });
}
