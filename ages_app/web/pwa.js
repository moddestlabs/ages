(function() {
  'use strict';

  function isStandalone() {
    return window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true ||
      document.referrer.includes('android-app://');
  }

  async function requestPersistentStorage() {
    if (!navigator.storage || !navigator.storage.persist) {
      return false;
    }

    if (await navigator.storage.persisted()) {
      return true;
    }

    return navigator.storage.persist();
  }

  async function getStorageEstimate() {
    if (!navigator.storage || !navigator.storage.estimate) {
      return null;
    }

    return navigator.storage.estimate();
  }

  function getServiceWorkerController() {
    return navigator.serviceWorker && navigator.serviceWorker.controller
      ? navigator.serviceWorker.controller
      : null;
  }

  function waitForServiceWorkerMessage(expectedType) {
    return new Promise((resolve, reject) => {
      if (!navigator.serviceWorker) {
        reject(new Error('service_worker_unavailable'));
        return;
      }

      const timeoutId = window.setTimeout(() => {
        navigator.serviceWorker.removeEventListener('message', onMessage);
        reject(new Error('service_worker_message_timeout'));
      }, 15000);

      function onMessage(event) {
        if (!event.data || event.data.type !== expectedType) {
          return;
        }

        window.clearTimeout(timeoutId);
        navigator.serviceWorker.removeEventListener('message', onMessage);
        resolve(event.data);
      }

      navigator.serviceWorker.addEventListener('message', onMessage);
    });
  }

  async function getCacheStatus() {
    const controller = getServiceWorkerController();
    if (!controller) {
      return null;
    }

    const responsePromise = waitForServiceWorkerMessage('CACHE_STATUS_RESULT');
    controller.postMessage({ type: 'GET_CACHE_STATUS' });
    const response = await responsePromise;
    return response.status;
  }

  async function getPwaDiagnostics() {
    const diagnostics = {
      timestamp: new Date().toISOString(),
      online: navigator.onLine,
      locationHref: window.location.href,
      standalone: isStandalone(),
      displayModeStandalone: window.matchMedia('(display-mode: standalone)').matches,
      iosStandalone: window.navigator.standalone === true,
      serviceWorkerSupported: 'serviceWorker' in navigator,
      serviceWorkerController: false,
      serviceWorkerControllerScriptUrl: null,
      serviceWorkerRegistrationScope: null,
      serviceWorkerRegistrationActiveScriptUrl: null,
      serviceWorkerRegistrationActiveState: null,
      cacheStatus: null,
      storageEstimate: null,
      errors: [],
    };

    try {
      const controller = getServiceWorkerController();
      diagnostics.serviceWorkerController = !!controller;
      diagnostics.serviceWorkerControllerScriptUrl = controller?.scriptURL || null;
    } catch (error) {
      diagnostics.errors.push('controller:' + String(error));
    }

    try {
      if (navigator.serviceWorker) {
        const registration = await navigator.serviceWorker.getRegistration();
        if (registration) {
          diagnostics.serviceWorkerRegistrationScope = registration.scope || null;
          diagnostics.serviceWorkerRegistrationActiveScriptUrl = registration.active?.scriptURL || null;
          diagnostics.serviceWorkerRegistrationActiveState = registration.active?.state || null;
        }
      }
    } catch (error) {
      diagnostics.errors.push('registration:' + String(error));
    }

    try {
      diagnostics.cacheStatus = await getCacheStatus();
    } catch (error) {
      diagnostics.errors.push('cache_status:' + String(error));
    }

    try {
      diagnostics.storageEstimate = await getStorageEstimate();
    } catch (error) {
      diagnostics.errors.push('storage:' + String(error));
    }

    return diagnostics;
  }

  async function initializePwa() {
    const persisted = await requestPersistentStorage();
    const storageEstimate = await getStorageEstimate();

    window.agesPwa = {
      standalone: isStandalone(),
      persisted,
      storageEstimate,
      isOnline: () => navigator.onLine,
      getCacheStatus,
      getPwaDiagnostics,
    };

    window.dispatchEvent(new CustomEvent('ages-pwa-ready', {
      detail: window.agesPwa,
    }));
  }

  window.addEventListener('online', () => {
    window.dispatchEvent(new CustomEvent('ages-online'));
  });

  window.addEventListener('offline', () => {
    window.dispatchEvent(new CustomEvent('ages-offline'));
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePwa);
  } else {
    initializePwa();
  }
})();