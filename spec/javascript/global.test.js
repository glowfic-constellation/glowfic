import '@testing-library/jest-dom';
const { loadGlobals } = require('./support/sprockets');

const { queryTransform } = loadGlobals('app/assets/javascripts/global.js', ['queryTransform']);

describe('queryTransform', () => {
  it('maps a select2 query into the API params the backend expects', () => {
    expect(queryTransform({ term: 'pixie', page: 2 })).toEqual({ q: 'pixie', page: 2 });
  });
});
