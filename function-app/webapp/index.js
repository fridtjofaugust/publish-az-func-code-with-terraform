module.exports = async function (context, req) {
    const status = 200
    const headers = {
        'content-type': 'text/html; charset=utf-8'
    }
    const body = 'Hello azure! this is only for testing'

    context.res = {
        status,
        headers,
        body,
    };
}
