import React from 'react';
import { Component } from 'react';
import _ from 'lodash';

const CheckBoxField = ({model, field, labelText, value, opts = {}}) => {
  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);

  return (
    <div className="field">
      <div className="control">
        <input name={`${model}[${field}]`} type="hidden" value="false" />
        <input
          className="checkbox"
          id={`${model}_${field}`}
          name={`${model}[${field}]`}
          type="checkbox"
          value="true"
        />
        <label htmlFor={`${model}_${field}`} className={labelClass}>
          {labelDisplay}
        </label>
      </div>
    </div>
  );
}

export default CheckBoxField;
