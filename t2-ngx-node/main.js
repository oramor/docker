import http from 'http';

const PORT = 3000;

const server = http.createServer((_, res) => {
    res.end('Hello');
});

server.listen(PORT, () => {
    console.log(`Server started on port ${PORT}...`);
});
