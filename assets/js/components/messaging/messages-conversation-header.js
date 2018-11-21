import _ from 'lodash';
import React from 'react';

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
        <i className="fas fa-angle-right has-padding-right-nudge"></i>
      }
      { conversation.company_name }
      { unseenCount > 0 &&
        <span className="messaging__notifications qa-messages-unseen-count">{unseenCount}</span>
      }
    </div>
  );
}

export default MessagesConversationHeader;
