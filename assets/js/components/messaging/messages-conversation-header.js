import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const MessagesConversationHeader = ({conversation, onSelect}) => {
  const unseenCount = _.chain(conversation.messages)
    .filter(['has_been_seen', false])
    .filter(['author_is_me', false])
    .size()
    .value();

  return (
    <div
        className={`qa-conversation-company-${conversation.company_name} ${unseenCount > 0 ? "with-unseen" : ""}`}
        onClick={() => onSelect && onSelect()}>
      { onSelect &&
        <FontAwesomeIcon icon="angle-right" className="has-padding-right-sm" />
      }
      { conversation.company_name }
      { unseenCount > 0 &&
        <span className="messaging__notifications qa-messages-unseen-count"><FontAwesomeIcon icon="envelope" className="has-margin-right-xs" /> {unseenCount}</span>
      }
    </div>
  );
}

export default MessagesConversationHeader;
