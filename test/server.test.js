const { app, server } = require('../app/server');
const request = require('supertest');
const axios = require('axios');
const MockAdapter = require('axios-mock-adapter');

describe('GET /api/insurance', () => {
  let mock;

  beforeAll(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  it('debe responder con datos de la API externa', async () => {
    const mockData = { insurance: 58, value: 100 };
    mock
      .onGet('https://dn8mlk7hdujby.cloudfront.net/interview/insurance/58')
      .reply(200, mockData);

    const response = await request(app).get('/api/insurance');
    expect(response.statusCode).toBe(200);
    expect(response.body).toEqual(mockData);
  });

  it('debe manejar errores de la API externa', async () => {
    mock
      .onGet('https://dn8mlk7hdujby.cloudfront.net/interview/insurance/58')
      .reply(500);

    const response = await request(app).get('/api/insurance');
    expect(response.statusCode).toBe(500);
    expect(response.body).toHaveProperty('error');
  });

  afterAll((done) => {
    if (server) {
      server.close(done);
    } else {
      done();
    }
  });
});
