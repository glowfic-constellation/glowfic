/* eslint no-undef: 0 */
describe('global', function() {
  var loggedInKey = 'loggedIn';
  describe('globalReady', function() {
    it('does not set localStorage.loggedIn if no gon', function() {
      expect(localStorage.getItem(loggedInKey)).toEqual(null);
      var callback = sinon.spy();
      window.addEventListener('storage', callback);
      globalReady();
      expect(callback.callCount).toEqual(0);
      expect(localStorage.getItem(loggedInKey)).toEqual(null);
    });

    it('should set localStorage.loggedIn if gon.logged_in set', function() {
      expect(localStorage.getItem(loggedInKey)).toEqual(null);
      window.gon = {logged_in: true};
      globalReady();
      expect(localStorage.getItem(loggedInKey)).toEqual('true');
    });

    it('should not set localStorage.loggedIn if gon.logged_in matches', function() {
      localStorage.setItem(loggedInKey, 'true');
      var callback = sinon.spy();
      window.addEventListener('storage', callback);
      window.gon = {logged_in: true};
      globalReady();
      expect(callback.callCount).toEqual(0);
      expect(localStorage.getItem(loggedInKey)).toEqual('true');
    });
  });
});
