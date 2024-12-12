export const visibilityMethods = {
    hideElements: function(selector, context) {
		console.log('Hiding: ' + selector + ' on ' + context);
		$(context).find(selector).hide();
    },
    
    unhideElements: function(selector, context) {
		$(context).find(selector).show();
    },
    
    disableElements: function(selector, context) {
		$(context).find(selector).prop('disabled', true);
    },
    
    enableElements: function(selector, context) {
		$(context).find(selector).prop('disabled', false);
    },
	
	readonlyElements: function(selector, context) {
		$(context).find(selector).prop('readonly', true);
    },
    
    notreadonlyElements: function(selector, context) {
		$(context).find(selector).prop('readonly', false);
    }
};
