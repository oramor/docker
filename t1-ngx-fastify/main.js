import Fastify from 'fastify';

const engine = Fastify({
    logger: true,
});

engine.get('/', (_, reply) => {
    reply.send({ hello: 'world' });
});

/**
 * Option { host: '0.0.0.0' } is very important for Docker deploying
 * See https://www.fastify.io/docs/latest/Reference/Server/#listen
 */
engine.listen({ port: 3000, host: '0.0.0.0' }, (err) => {
    if (err) throw err;
});
