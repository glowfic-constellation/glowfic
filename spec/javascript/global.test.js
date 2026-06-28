import '@testing-library/jest-dom';

const { queryTransform } = require('../../app/assets/javascripts/global');

describe('queryTransform', () => {
  it('maps a select2 query into the API params the backend expects', () => {
    const result = queryTransform({ term: 'pixie', page: 2 });
    expect(result).toEqual({ q: 'pixie', page: 2 });
  });
});
