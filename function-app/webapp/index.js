module.exports = async function (context, req) {
    const status = 200
    const headers = {
        'content-type': 'text/html; charset=utf-8'
    }
    const body = 'Hello azure! this is test. Is this working'

    context.res = {
        status,
        headers,
        body,
    };
}
